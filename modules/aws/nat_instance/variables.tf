variable "name" {
  description = "Name used for resources created within the module"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the NAT instance into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy the NAT instance into. Should be a public subnet!"
  type        = string
}

variable "route_table_id" {
  description = "Route table to update."
  type        = string
}

variable "encryption" {
  description = "Whether or not to encrypt the EBS volume"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type to use for the NAT instance"
  type        = string
  default     = "t4g.micro"
}

variable "ami_id" {
  description = "AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided"
  type        = string
  default     = null
}



variable "ebs_root_volume_size" {
  description = "Size of the EBS root volume in GB"
  type        = number
  default     = 8
}

variable "use_spot_instances" {
  description = "Whether or not to use spot instances for running the NAT instance"
  type        = bool
  default     = false
}

variable "use_cloudwatch_agent" {
  description = "Whether or not to enable CloudWatch agent for the NAT instance"
  type        = bool
  default     = true
}

variable "cloudwatch_agent_configuration" {
  description = "CloudWatch configuration for the NAT instance"
  type = object({
    namespace           = optional(string, "nat-instance"),
    collection_interval = optional(number, 60),
    endpoint_override   = optional(string, "")
  })
  default = {
    namespace           = "nat-instance"
    collection_interval = 60
    endpoint_override   = ""
  }
}

variable "cloudwatch_agent_configuration_param_arn" {
  description = "ARN of the SSM parameter containing the CloudWatch agent configuration. If none provided, creates one"
  type        = string
  default     = null
}

variable "use_default_security_group" {
  description = "Whether or not to use the default security group for the NAT instance"
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "A list of identifiers of security groups to be added for the NAT instance"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources created within the module"
  type        = map(string)
  default     = {}
}