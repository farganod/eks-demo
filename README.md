# Demo EKS Stack Deployment EC2 with IRSA

This code supports a the deployment of EKS Cluster with the potential for multi-tenancy. Leveraging `terraform` as the IaC this can be run locally with correct credentials or through a pipeline. This stack supports IAM roles for Service Account (IRSA) for fine grained pod permissions. For the kubernetes app deployment I forked from the demo repo [s3-echoer](https://github.com/mhausenblas/s3-echoer) and modified the yaml template to support the region I was working in. My forked repo can is [farganod/s3-echoer](https://github.com/farganod/s3-echoer)

The blog post this stack is used to deploy is [fine grained roles for eks service accounts](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)

The following resources are used to deploy this environment:

## Resources

* [VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
* [EKS Cluster Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
* [IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
* [IAM Policy Attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment)
* [S3 Bucket](https://www.terraform.io/docs/providers/aws/r/s3_bucket.html)

# Usage

## Pre-requisites

Prior to using this repo you will need terraform installed on the system running the code link to Terraform site below:

* [Terraform Download](https://www.terraform.io/downloads.html)
* [Terraform Install Guide](https://learn.hashicorp.com/terraform/getting-started/install)

## Running Code

Once terraform is installed To run the code you will need to initialize terraform working environment.

*Example:*
`terraform init`

Once working environment has been established you can now execute the build of the environment by sending the specified JSON file.

*Structure:*

`terraform apply --var-file=<env>.json`

*Example:*

`terraform apply --var-file=demo.json`

# Code Build YAMLs

I manually deployed the AWS Code Build environemnts and placed the `buildspec.yaml` commands directly in each of the environments. Below are contents of each for posterity

## eks-demo (terraform build)

```
version: 0.2

phases:

  install:
    commands:
      - "apt install unzip -y"
      - "wget https://releases.hashicorp.com/terraform/0.14.9/terraform_0.14.9_linux_amd64.zip"
      - "unzip terraform_0.14.9_linux_amd64.zip"
      - "mv terraform /usr/local/bin/"
      - "terraform -version"
  pre_build:
    commands:
      - terraform init

  build:
    commands:
      - terraform apply -var-file=demo.json -auto-approve

  post_build:
    commands:
      - echo terraform apply completed on `date`
```
## eks-demo-deployment (kubernetes job deployment)

```
version: 0.2
phases:
  pre_build:
    commands:
      - aws eks --region us-east-1 update-kubeconfig --name eks-demo
      - kubectl get nodes
      - aws s3api list-objects --bucket eks-demo-test123
  build:
    commands:
      - kubectl create sa s3-echoer
      - kubectl annotate sa s3-echoer eks.amazonaws.com/role-arn=arn:aws:iam::175039216299:role/eks-demo-service-role
      - sed -e "s/TARGET_BUCKET/eks-demo-test123/g" s3-echoer-job.yaml.template > s3-echoer-job.yaml
      - kubectl apply -f s3-echoer-job.yaml
  post_build:
    commands:
      - sleep 10
      - kubectl logs job/s3-echoer
      - aws s3api list-objects --bucket eks-demo-test123
      - aws s3 rm s3://eks-demo-test123 --recursive
      - kubectl delete job/s3-echoer
      - kubectl delete sa s3-echoer
```
