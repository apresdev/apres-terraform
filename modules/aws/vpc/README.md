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


<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->