variable "guardduty_enable_s3_protection" {
  description = "Enable GuardDuty to monitor S3 buckets"
  type        = bool
  default     = true
}

variable "guardduty_enable_eks_protection" {
  description = "Enable GuardDuty to monitor EKS clusters"
  type        = bool
  default     = true
}

# Not supported yet, there's a manual setting in the management account that needs to get set somehow.
# variable "guardduty_enable_malware_protection" {
#   description = "Enable GuardDuty to monitor EBS volumes for malware.""
#   type        = bool
#   default     = true
# }

variable "guardduty_enable_rds_protection" {
  description = "Enable GuardDuty to monitor RDS instances"
  type        = bool
  default     = true
}

variable "guardduty_enable_lambda_protection" {
  description = "Enable GuardDuty to monitor Lambda functions"
  type        = bool
  default     = true
}

variable "inspector_enable_ec2_scanning" {
  description = "Enable Inspector to scan EC2 instances"
  type        = bool
  default     = true
}

variable "inspector_enable_ecr_scanning" {
  description = "Enable Inspector to scan ECR repositories"
  type        = bool
  default     = true
}

variable "inspector_enable_lambda_scanning" {
  description = "Enable Inspector to scan Lambda functions"
  type        = bool
  default     = true
}

variable "inspector_enable_lambda_code_scanning" {
  description = "Enable Inspector to scan Lambda function code"
  type        = bool
  default     = true
}

variable "inspector_member_accounts" {
  description = <<EOF
    List of member account IDs to enable Inspector on. The audit account has no way to look these up,
    so you must specify them here.

    This list should include all accounts in the Workloads OU and Infrastructure OU, and any other
    account where you want Inspector to run. Do not include the audit account here.
  EOF
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  default     = "SecurityTools"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "environment" {
  description = "Environment Name, used for naming and tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}