# Apres VPC Terraform module

## Overview

This module will create a VPC, with subnets in three AZs. The module creates three tiers of subnets:

| Subnet | Public IPs | Internet Access | Usage |
|--------|------------|-----------------|-------|
| Public | Yes | Yes  | Only internet-facing services are deployed here, typically API Gateway and public load balancers. |
| Private | No | Yes | Most services are deployed here. These subnets have internet-access. |
| Persistence | No | No | This subnet is used for deploying RDS, Kafka etc, and can only be accessed from the Private subnets, and has no direct internet access, both enforced by NACL’s. |

Instead of the rather expensive Managed NAT Gateway, this VPC uses the [fck-nat](https://fck-nat.dev/stable/) AMI, which is an EC2 instance based on Amazon Linux 2 acting as a NAT instance, deployed in autoscale groups to handle rolling upgrades and terminations.

VPC Flow Logs are enabled, writing to CloudWatch Logs.

The module also creates a simple CloudWatch dashboard to monitor the NAT instances.

### CIDR Ranges and VPC Layout

A default CIDR range is not set on purpose, ranges should be carefully planned ahead of time.

Apres _strongly_ recommends selecting unique CIDR ranges for each VPC in your organization, for two main reasons:
1. If at any point in the future you need to connect your VPC's with VPC Peering or Transit Gateway, it will not be
   possible of CIDR ranges overlap. Changing CIDR ranges in a VPC is not possible, and it would require rebuilding
   all your services in a new VPC.
2. It is much easier to reason about separate ranges especially when investigating security incidents.

Apres recommends using a layout as follows, and uses the same internally. There is no real reason
for leaving gaps in ranges other than convention and ease of reading:

| Account Name | Region      | CIDR      |
| ------------ | ----------- | --------- |
| Sandbox      | us-east-2   | 10.90/16  |
| Dev          | us-east-2   | 10.100/16 |
| Test         | us-east-2   | 10.110/16 |
| Prod         | us-east-2   | 10.120/16 |

Using the Dev/us-east-2 CIDR range of 10.100/16 as an example, deploying this module will result in the following
subnet layout:

Subnet ranges are the same in each VPC, showing Dev here for an example. [Source](https://www.davidc.net/sites/default/subnets/subnets.html?network=10.100.0.0&mask=16&division=45.f72399c98c40)

| CIDR | Number of IPs | Purpose |
| ---- | ------------- | ------- |
| 10.100.0.0/23   | 510  | Public Subnet 1 |
| 10.100.2.0/23   | 510  | Public Subnet 2 |
| 10.100.4.0/23   | 510  | Public Subnet 3 |
| 10.100.6.0/23   | 510  | Reserved Public Subnet 4 |
| 10.100.8.0/23   | 510  | Reserved Public Subnet 5 |
| 10.100.10.0/23  | 510  | Reserved Public Subnet 6|
| 10.100.12.0/23  | 510  | Unused |
| 10.100.14.0/23  | 510  | Unused |
| 10.100.16.0/22  | 1022 | Persistence Subnet 1 |
| 10.100.20.0/22  | 1022 | Persistence Subnet 2 |
| 10.100.24.0/22  | 1022 | Persistence Subnet 3 |
| 10.100.28.0/22  | 1022 | Reserved Persistence Subnet 4 |
| 10.100.32.0/22  | 1022 | Reserved Persistence Subnet 5 |
| 10.100.36.0/22  | 1022 | Reserved Persistence Subnet 6 |
| 10.100.40.0/22  | 4096 | Unused |
| 10.100.44.0/22  | 4096 | Unused |
| 10.100.48.0/20  | 4096 | Unused |
| 10.100.64.0/19  | 8190 | Private Subnet 1 |
| 10.100.96.0/19  | 8190 | Private Subnet 2 |
| 10.100.128.0/19 | 8190 | Private Subnet 3 |
| 10.100.160.0/19 | 8190 | Reserved Private Subnet 4 |
| 10.100.192.0/19 | 8190 | Reserved Private Subnet 5 |
| 10.100.224.0/19 | 8190 | Reserved Private Subnet 6 |

The _Reserved_ subnets are not deployed, but the ranges are listed future expansion.

## Service Endpoints

Service Endpoints are supported, but note that S3, DynamoDB and Sagemaker are special cases.
Sagemaker endpoints are not supported in this module because of the non-standard DNS names provided.
S3 and DynamoDB are supported for both Interface and Gateway styles. See the notes for the variable `vpc_service_endpoints` for a more
in-depth discussion, and these links:
* [AWS Services that integrate with AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html)
* [AWS PrivateLink for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html)
* [AWS PrivateLink for DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/privatelink-interface-endpoints.html)

Also take note of the cost of Service Endpoints, which at time of writing is roughly $7 per endpoint per subnet per month. Which
in translates to $21 per month for a single endpoint, plus bandwidth costs.

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
    "arn:aws:iam::*:role/*vpc*",
    "arn:aws:iam::${AWS::AccountId}:policy/*vpc*",
    "arn:aws:iam::${AWS::AccountId}:role/*vpc*",
    "arn:aws:iam::${AWS::AccountId}:instance-profile/*vpc*",
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.34.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nat_instance"></a> [nat\_instance](#module\_nat\_instance) | git@github.com:apresdev/apres-terraform.git//modules/aws/nat_instance | rel/nat_instance/1.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_flow_log.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_policy.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
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
| [aws_vpc_endpoint.dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
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
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | `"VPC"` | no |
| <a name="input_enable_dynamodb_gateway_endpoint"></a> [enable\_dynamodb\_gateway\_endpoint](#input\_enable\_dynamodb\_gateway\_endpoint) | Enable the DynamoDB VPC Gateway endpoint. See notes on vpc\_service\_endpoints for details. | `bool` | `false` | no |
| <a name="input_enable_s3_gateway_endpoint"></a> [enable\_s3\_gateway\_endpoint](#input\_enable\_s3\_gateway\_endpoint) | Enable the S3 VPC Gateway endpoint. See notes on vpc\_service\_endpoints for details. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_nat_instance_dashboard_name"></a> [nat\_instance\_dashboard\_name](#input\_nat\_instance\_dashboard\_name) | Name of the NAT Instance Dashboard | `string` | `"NATInstanceDashboard"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. For example '10.100.0.0/16' | `string` | n/a | yes |
| <a name="input_vpc_flow_log_retention_days"></a> [vpc\_flow\_log\_retention\_days](#input\_vpc\_flow\_log\_retention\_days) | Retention days for the VPC flow logs, see CloudWatch Logs for valid values. | `number` | `365` | no |
| <a name="input_vpc_flow_log_traffic_type"></a> [vpc\_flow\_log\_traffic\_type](#input\_vpc\_flow\_log\_traffic\_type) | Flow Logs Traffic Type, one of 'ACCEPT', 'REJECT', or 'ALL' | `string` | `"REJECT"` | no |
| <a name="input_vpc_nat_instance_type"></a> [vpc\_nat\_instance\_type](#input\_vpc\_nat\_instance\_type) | Instance type for the NAT instance | `string` | `"t4g.nano"` | no |
| <a name="input_vpc_persistence_subnet_cidrs"></a> [vpc\_persistence\_subnet\_cidrs](#input\_vpc\_persistence\_subnet\_cidrs) | The CIDR block for the persistence subnets. For example: ["10.100.64.0/20", "10.100.80.0/20", "10.100.96.0/20"] | `list(string)` | n/a | yes |
| <a name="input_vpc_private_subnet_cidrs"></a> [vpc\_private\_subnet\_cidrs](#input\_vpc\_private\_subnet\_cidrs) | The CIDR block for the private subnets. For example: ["10.100.16.0/20", "10.100.32.0/20", "10.100.48.0/20"] | `list(string)` | n/a | yes |
| <a name="input_vpc_public_subnet_cidrs"></a> [vpc\_public\_subnet\_cidrs](#input\_vpc\_public\_subnet\_cidrs) | List of 3 CIDR blocks for the private subnets. For example, ["10.100.0.0/23", "10.100.2.0/23", "10.100.4.0/23"] | `list(string)` | n/a | yes |
| <a name="input_vpc_service_endpoints"></a> [vpc\_service\_endpoints](#input\_vpc\_service\_endpoints) | List of VPC endpoints of AWS Services to create, use the service name. For example  ["ec2messages", "ssm", "ssmmessages"]<br/>    will setup VPC endpoints for SSM Session Manager to work without internet access. These will be interpreted into<br/>    endpoints with the name 'com.amazonaws.<region>.<service>' and as such Sagemaker is not supported, but not enforced.<br/>    See https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html for the list<br/>    of supported services.<br/><br/>    Endpoints will be created as Interface endpoints, using AWS PrivateLink. Interface endpoints cost $7 per AZ,<br/>    per month, plus bandwidth. A single endpoint deployed to 3 AZs will cost $21 per month.<br/><br/>    S3 and Dynamodb endpoints are special cases, they can be setup as Interface and/or Gateway endpoints, both can<br/>    be deployed at the same time. See<br/>    https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html#types-of-vpc-endpoints-for-s3<br/>    for the details. To enable S3 or DynamoDB _service_ endpoints, add them to this list.<br/>    To enable the VPC Gateway endpoints, set the variables `enable_s3_vpc_endpoint` and `enable_dynamodb_vpc_endpoint`. The<br/>    Gateway endpoints are not billed, but use public IP addresses instead of private ones.<br/><br/>    Note that Gateway endpoints are not enabled in the "persistence" subnets, since Gateway endpoints have public IP addresses<br/>    and the persistence subnets do not have routes to the public Internet.<br/>    If you _really_ need services in the persistence subnets to access S3 and DynamoDB, use the Interface endpoints. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_persistence_subnet_ids"></a> [persistence\_subnet\_ids](#output\_persistence\_subnet\_ids) | List of Persistence Subnet IDs |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of Private Subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of Public Subnet IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
<!-- END_TF_DOCS -->