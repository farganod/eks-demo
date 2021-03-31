# Full Stack EKS Deployment On Fargate

This code supports a full stack deployment EKS Cluster with the potential for multiple containers running on a single task definition. Leveraging `terraform` as the IaC this can be run locally with correct credentials or through a pipeline.

The following resources are used to deploy this environment:

* [VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.44.0)
* [Cloudwatch Log Group](https://www.terraform.io/docs/providers/aws/r/cloudwatch_log_group.html)
* [S3 Bucket](https://www.terraform.io/docs/providers/aws/r/s3_bucket.html)
* [S3 Bucket Policy](https://www.terraform.io/docs/providers/aws/r/s3_bucket_policy.html)
* [Security Group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [Load Balancer v2](https://www.terraform.io/docs/providers/aws/r/lb.html)
* [Load Balancer Target Group](https://www.terraform.io/docs/providers/aws/r/lb_target_group.html)
* [Load Balancer Lisenter](https://www.terraform.io/docs/providers/aws/r/lb_listener.html)
* [ECS Cluster](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html)
* [ECS Task Definition](https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html)
* [ECS Service](https://www.terraform.io/docs/providers/aws/r/ecs_service.html)
* [Application Autoscaling](https://www.terraform.io/docs/providers/aws/r/appautoscaling_target.html)
* [Application Autoscaling Policy](https://www.terraform.io/docs/providers/aws/r/appautoscaling_policy.html)
* [CloudWatch Alarm](https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html)

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

*The expected output of the command:*

```
terraform apply --var-file=dev.json
data.aws_secretsmanager_secret_version.secrets: Refreshing state...
module.vpc.data.aws_iam_policy_document.vpc_flow_log_cloudwatch[0]: Refreshing state...
module.vpc.data.aws_iam_policy_document.flow_log_cloudwatch_assume_role[0]: Refreshing state...
data.aws_availability_zones.available: Refreshing state...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_appautoscaling_policy.scale_down_policy will be created
  + resource "aws_appautoscaling_policy" "scale_down_policy" {
      + arn                = (known after apply)
      + id                 = (known after apply)
      + name               = "scale-down"
      + policy_type        = "StepScaling"
      + resource_id        = "service/VirtualAdviser-Dev/VirtualAdviser-Dev-service"
      + scalable_dimension = "ecs:service:DesiredCount"
      + service_namespace  = "ecs"

      + step_scaling_policy_configuration {
          + adjustment_type         = "ChangeInCapacity"
          + cooldown                = 60
          + metric_aggregation_type = "Average"

          + step_adjustment {
              + metric_interval_upper_bound = "0"
              + scaling_adjustment          = -1
            }
        }
    }

...
# module.vpc.aws_vpc.this[0] will be created
+ resource "aws_vpc" "this" {
    + arn                              = (known after apply)
    + assign_generated_ipv6_cidr_block = false
    + cidr_block                       = "10.0.0.0/16"
    + default_network_acl_id           = (known after apply)
    + default_route_table_id           = (known after apply)
    + default_security_group_id        = (known after apply)
    + dhcp_options_id                  = (known after apply)
    + enable_classiclink               = (known after apply)
    + enable_classiclink_dns_support   = (known after apply)
    + enable_dns_hostnames             = false
    + enable_dns_support               = true
    + id                               = (known after apply)
    + instance_tenancy                 = "default"
    + ipv6_association_id              = (known after apply)
    + ipv6_cidr_block                  = (known after apply)
    + main_route_table_id              = (known after apply)
    + owner_id                         = (known after apply)
    + tags                             = {
        + "Environment" = "dev"
        + "Name"        = "VirtualAdviser-Dev"
        + "Terraform"   = "true"
      }
  }

Plan: 42 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
Terraform will perform the actions described above.
Only 'yes' will be accepted to approve.
```
Enter `yes` to approve the build

