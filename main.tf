#Data resoruces to get the az in regions deploying to
data "aws_availability_zones" "available" {
  state = "available"
}

# Data for cluster deployed to used for kube provider
data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_id
}

# Data for cluster auth deployed to used for kube provider
data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_id
}

# Establishes kube proivder for configuring the IRSA
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# Module to deploy out full network infrastructure
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.env_name
  cidr = var.cidr_block

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  private_subnets = [cidrsubnet(var.cidr_block, 4, 0), cidrsubnet(var.cidr_block, 4, 1), cidrsubnet(var.cidr_block, 4, 2)]
  public_subnets  = [cidrsubnet(var.cidr_block, 4, 3), cidrsubnet(var.cidr_block, 4, 4), cidrsubnet(var.cidr_block, 4, 5)]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}

# Module to create the eks cluster with IRSA enabled
module "cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.env_name
  cluster_version = "1.19"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  enable_irsa     = true

  worker_groups = [
    {
      instance_type = "t3.medium"
      asg_max_size  = 3
    }
  ]
  workers_group_defaults = {
  	root_volume_type = "gp2"
  }
}

# Creates the iam role with assume role policy for service account
resource "aws_iam_role" "role" {
  name = "eks-demo-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.cluster.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${trimprefix(module.cluster.cluster_oidc_issuer_url,"https://")}:sub": "system:serviceaccount:default:${var.sa_name}"
        }
      }
    }
  ]
}
EOF
  depends_on = [
    module.cluster,
  ]
}

# Attaches S3 Full access to role
resource "aws_iam_policy_attachment" "role-attach" {
  name       = "role-attachment"
  roles      = [aws_iam_role.role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Creates Bucket for used in demo
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.env_name}-test123"
}