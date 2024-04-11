# Apres VPC Terraform module

## Overview

This module will create a VPC, with subnets in three AZs. There are three tiers of subnets:

| Subnet | Public IPs | Internet Access | Usage |
|--------|------------|-----------------|-------|
| Public | Yes | Yes  | Only internet-facing services are deployed here, typically API Gateway and public load balancers. |
| Private | No | Yes | Most services are deployed here. These subnets have internet-access. |
| Persistence | No | No | This subnet is used for deploying RDS, Kafka etc, and can only be accessed from the Private subnets, and has no direct internet access, both enforced by NACL’s. |

Instead of the rather expensive Managed NAT Gateway, this VPC uses the [fck-nat](https://fck-nat.dev/stable/) AMI, which is an EC2 instance based on Amazon Linux 2 acting as a NAT instance, deployed in autoscale groups to handle rolling upgrades and terminations.

VPC Flow Logs are enabled, writing to CloudWatch Logs.

The module also creates a simple CloudWatch dashboard to monitor the NAT instances.

CIDR ranges are purposely not set, accepting the defaults could be difficult to undo later.

## Example

```hcl
module "vpc" {
  source                       = "../../../modules/apres_vpc"
  environment                  = "Dev"
  vpc_cidr                     = "10.100.0.0/16"
  vpc_public_subnet_cidrs      = ["10.100.0.0/23", "10.100.2.0/23", "10.100.4.0/23"]
  vpc_private_subnet_cidrs     = ["10.100.16.0/23", "10.100.32.0/23", "10.100.48.0/23"]
  vpc_persistence_subnet_cidrs = ["10.100.64.0/20", "10.100.80.0/20", "10.100.96.0/20"]
  vpc_nat_instance_type        = "t4g.nano"
  vpc_flow_log_traffic_type    = "REJECT"
}
```

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed.
Substitute `${AWS::Region}` with the region where this is deployed.

```jsonc
{
  "Effect": "Allow",
  "Action": [
    "autoscaling:*",
    "cloudwatch:*",
    "ec2:*",
    "kms:*",
    "logs:*"
  ],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": "iam:*",
  "Resource": [
    "arn:aws:iam::*:role/vpc*",
    "arn:aws:iam::${AWS::AccountId}:role/vpc*",
    "arn:aws:iam::${AWS::AccountId}:instance-profile/vpc*",
    "arn:aws:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    "arn:aws:iam::${AWS::AccountId}:policy/GitHubActionsECRServicePolicy*",
    "arn:aws:iam::${AWS::AccountId}:role/GitHubActionsECRServiceRole*",
  ]
},
{
  "Effect": "Allow",
  // Allow managing SSM parameters for VPC Nat instances, but need to give "*" as the resource because
  // how the Terraform AWS provider uses DescribeParameters.
  "Action": "ssm:*",
  "Resource": "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:*"
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.34.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nat_instance"></a> [nat\_instance](#module\_nat\_instance) | ../nat_instance | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_flow_log.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_internet_gateway.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_network_acl.persistence_network_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_association.persistence](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_rule.allow_private_subnet_traffic_in_0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.allow_private_subnet_traffic_in_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.allow_private_subnet_traffic_in_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.allow_private_subnet_traffic_out_0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.allow_private_subnet_traffic_out_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.allow_private_subnet_traffic_out_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.block_internet_traffic_in](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.block_internet_traffic_out](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_route_table.persistence_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.persistence_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.vpc_service_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.persistence_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.service_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_ami.fck_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_flow_logs_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to all resources | `map(string)` | <pre>{<br>  "application": "VPC",<br>  "managed-by": "terraform",<br>  "owner": "Engineering"<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for tagging AWS resources. | `string` | `"Dev"` | no |
| <a name="input_nat_instance_dashboard_name"></a> [nat\_instance\_dashboard\_name](#input\_nat\_instance\_dashboard\_name) | Name of the NAT Instance Dashboard | `string` | `"NATInstanceDashboard"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. For example '10.100.0.0/16' | `string` | n/a | yes |
| <a name="input_vpc_flow_log_retention_days"></a> [vpc\_flow\_log\_retention\_days](#input\_vpc\_flow\_log\_retention\_days) | Retention days for the VPC flow logs, see CloudWatch Logs for valid values. | `number` | `365` | no |
| <a name="input_vpc_flow_log_traffic_type"></a> [vpc\_flow\_log\_traffic\_type](#input\_vpc\_flow\_log\_traffic\_type) | Flow Logs Traffic Type, one of 'ACCEPT', 'REJECT', or 'ALL' | `string` | `"REJECT"` | no |
| <a name="input_vpc_nat_instance_type"></a> [vpc\_nat\_instance\_type](#input\_vpc\_nat\_instance\_type) | Instance type for the NAT instance | `string` | `"t4g.nano"` | no |
| <a name="input_vpc_persistence_subnet_cidrs"></a> [vpc\_persistence\_subnet\_cidrs](#input\_vpc\_persistence\_subnet\_cidrs) | The CIDR block for the persistence subnets. For example: ['10.100.64.0/20', '10.100.80.0/20', '10.100.96.0/20'] | `list(string)` | n/a | yes |
| <a name="input_vpc_private_subnet_cidrs"></a> [vpc\_private\_subnet\_cidrs](#input\_vpc\_private\_subnet\_cidrs) | The CIDR block for the private subnets. For example: ['10.100.16.0/20', '10.100.32.0/20', '10.100.48.0/20'] | `list(string)` | n/a | yes |
| <a name="input_vpc_public_subnet_cidrs"></a> [vpc\_public\_subnet\_cidrs](#input\_vpc\_public\_subnet\_cidrs) | List of 3 CIDR blocks for the private subnets. For example, ['10.100.0.0/23', '10.100.2.0/23', '10.100.4.0/23'] | `list(string)` | n/a | yes |
| <a name="input_vpc_service_endpoints"></a> [vpc\_service\_endpoints](#input\_vpc\_service\_endpoints) | List of VPC endpoints of AWS Services to create, use the service name. For example  ["ec2messages", "ssm", "ssmmessages"]<br>    will setup VPC endpoints for SSM Session Manager to work without internet access. These will be interpreted into<br>    endpoints wiht the name 'com.amazonaws.<region>.<service>' and as such Sagemaker is not supported. Also S3 and DynamoDB<br>    are not supported in this provider since they are Gateway endpoints, not Interface endpoints.<br>    See https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html for the list<br>    of supported services. Note these cost $7 each per month plus bandwidth. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_dashboard_url"></a> [nat\_dashboard\_url](#output\_nat\_dashboard\_url) | URL for the NAT Instance Dashboard |
| <a name="output_persistence_subnet_ids"></a> [persistence\_subnet\_ids](#output\_persistence\_subnet\_ids) | List of Persistence Subnet IDs |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of Private Subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of Public Subnet IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
<!-- END_TF_DOCS -->