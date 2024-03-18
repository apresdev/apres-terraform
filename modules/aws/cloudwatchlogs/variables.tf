variable "name" {
  description = <<EOF
    Description name of the CloudWatch Logs Group, used for tagging AWS resources.
    EOF
  type        = string
}

variable "path" {
  description = <<EOF
    Path of the CloudWatch Logs Group, should be a path like /acme/blah
    EOF
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_/-]+$", var.path))
    error_message = "Path must be a valid CloudWatch Logs path"
  }
}

# The retention periods are set by AWS.
variable "retention_in_days" {
  description = <<EOF
    The number of days to retain the log events in the log group. Valid values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.
    EOF
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.retention_in_days)
    error_message = "Cloudwatch Logs retention days must be one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "environment" {
  description = "Environment Name, used for tagging AWS resources."
  type        = string
  default     = "Dev"
}

variable "default_tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default = {
    "owner"      = "Engineering"
    "managed-by" = "terraform"
  }
}

variable "cwl_kms_alias_name" {
  description = "The alias name of the KMS key used to encrypt the CloudWatch Log Group. The full ARN will be constructed using the current region and account id."
  type        = string
  default     = "alias/apres/cloudwatchlogs"
}