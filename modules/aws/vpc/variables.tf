variable "default_tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default = {
    "application" = "VPC"
    "owner"       = "Engineering"
    "managed-by"  = "terraform"
  }
}

variable "environment" {
  description = "Environment Name, used for tagging AWS resources."
  type        = string
  default     = "Dev"
}

# Not giving details for the CIDR ranges, just examples, because getting it wrong is very bad.
variable "vpc_cidr" {
  description = "The CIDR block for the VPC. For example '10.100.0.0/16'"
  type        = string
  #default     = "10.100.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR."
  }
}

# NOTE: Assumes 3 AZs and 3 Subnets in each!
variable "vpc_public_subnet_cidrs" {
  description = <<EOF
  List of 3 CIDR blocks for the private subnets. For example, ["10.100.0.0/23", "10.100.2.0/23", "10.100.4.0/23"]
  EOF
  type        = list(string)
  validation {
    condition     = can([for cidr in var.vpc_public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "value must be a valid CIDR block"
  }
  validation {
    condition     = length(var.vpc_public_subnet_cidrs) == 3
    error_message = "Must be exactly 3 CIDR blocks."
  }
}

variable "vpc_private_subnet_cidrs" {
  description = <<EOF
  The CIDR block for the private subnets. For example: ["10.100.16.0/20", "10.100.32.0/20", "10.100.48.0/20"]
  EOF
  type        = list(string)
  validation {
    condition     = can([for cidr in var.vpc_private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "value must be a valid CIDR block"
  }
  validation {
    condition     = length(var.vpc_private_subnet_cidrs) == 3
    error_message = "Must be exactly 3 CIDR blocks."
  }
}

variable "vpc_persistence_subnet_cidrs" {
  description = <<EOF
  The CIDR block for the persistence subnets. For example: ["10.100.64.0/20", "10.100.80.0/20", "10.100.96.0/20"]
  EOF
  type        = list(string)
  validation {
    condition     = can([for cidr in var.vpc_persistence_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "value must be a valid CIDR block"
  }
  validation {
    condition     = length(var.vpc_persistence_subnet_cidrs) == 3
    error_message = "Must be exactly 3 CIDR blocks."
  }
}

variable "vpc_nat_instance_type" {
  description = "Instance type for the NAT instance"
  type        = string
  default     = "t4g.nano"
}

# This retention number is a bit nuts but that's what comes from AWS Docs.
variable "vpc_flow_log_retention_days" {
  description = "Retention days for the VPC flow logs, see CloudWatch Logs for valid values."
  type        = number
  default     = 365
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.vpc_flow_log_retention_days)
    error_message = "VPC FLow Logs retention days must be one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "vpc_flow_log_traffic_type" {
  description = "Flow Logs Traffic Type, one of 'ACCEPT', 'REJECT', or 'ALL'"
  type        = string
  default     = "REJECT"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.vpc_flow_log_traffic_type)
    error_message = "The vpc_flow_log_retention_type value must be one of 'ACCEPT', 'REJECT', or 'ALL'."
  }
}

variable "nat_instance_dashboard_name" {
  description = "Name of the NAT Instance Dashboard"
  type        = string
  default     = "NATInstanceDashboard"
}

variable "vpc_service_endpoints" {
  description = <<EOF
    List of VPC endpoints of AWS Services to create, use the service name. For example  ["ec2messages", "ssm", "ssmmessages"]
    will setup VPC endpoints for SSM Session Manager to work without internet access. These will be interpreted into
    endpoints with the name 'com.amazonaws.<region>.<service>' and as such Sagemaker is not supported.
    See https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html for the list
    of supported services.

    Endpoints will be created as Interface endpoints, using AWS PrivateLinke. Interface endpoints cost $7 per AZ,
    per month, plus bandwidth. A single endpoint deployed to 3 AZs will cost $21 per month.

    S3 and Dynamodb endpoints are special cases, they can be setup as Interface and/or Gateway endpoints, both can
    be deployed at the same time. See
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html#types-of-vpc-endpoints-for-s3
    for the details. To enable S3 or DynamoDB _service_ endpoints, add them to this list.
    To enable the VPC Gateway endpoints, set the variables `enable_s3_vpc_endpoint` and `enable_dynamodb_vpc_endpoint`. The
    Gateway endpoints are not billed, but use public IP addresses instead of private ones.

    Note that Gateway endpoints are not applied to the "persistence" subnets, since those subnets do not have routes
    to public IP addresses, and Gateway endpoints have public IP addresses. If you wish the persistence subnets
    to access S3 and DynamoDB, use the Interface endpoints.
  EOF
  type        = list(string)
  default     = []
  # TODO: validate that s3 and dynamodb aren't set here
}

variable "enable_s3_gateway_endpoint" {
  description = "Enable the S3 VPC Gateway endpoint. See notes on vpc_service_endpoints for details."
  type        = bool
  default     = false
}

variable "enable_dynamodb_gateway_endpoint" {
  description = "Enable the DynamoDB VPC Gateway endpoint. See notes on vpc_service_endpoints for details."
  type        = bool
  default     = false
}