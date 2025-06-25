variable "name" {
  description = <<EOF
    Description name of the CloudWatch Logs Group, used for tagging AWS resources.
    EOF
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
  }
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
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
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

variable "cwl_kms_alias_name" {
  description = "The alias name of the KMS key used to encrypt the CloudWatch Log Group. The full ARN will be constructed using the current region and account id."
  type        = string
  default     = "alias/apres/cloudwatchlogs"
}

variable "region" {
  description = "Region to deploy to, using enhanced region support. Default is to use the provider configuration."
  type        = string
  default     = ""

}