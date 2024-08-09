variable "environment" {
  description = "Environment name, used for tagging AWS resources, and in the bucket name."
  type        = string
  default     = "dev"
  nullable    = false
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
  nullable    = false
}

# From: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-trail-naming-requirements.html#KMS-key-naming-requirements
# The name of the topic you want to create. Topic names must include only uppercase and lowercase ASCII letters, numbers, underscores, and 
# hyphens, and must be between 1 and 256 characters long.
#
# The overhead of our standard naming convention is approximately 40 characters (which includes the account id, the region, the 
# environment, and the optional deadletter suffix), so we will restrict the user supplied input to 200 characters to attempt to avoid 
# overloading the full SNS topic name limitations.
variable "name" {
  description = "Name of the queue, must be between 3 and 40 characters long and can contain only the following characters: a-z, A-Z, 0-9, _, and -"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.name) >= 3 && length(var.name) < 200
    error_message = "Name length must be between 3 and 200 characters."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-]*$", var.name))
    error_message = "The name only contain letters, numbers, underscores, hyphens, and dots."
  }
}
