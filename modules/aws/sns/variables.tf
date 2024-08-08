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

# From: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sns-topic.html
# The name of the topic you want to create. Topic names must include only uppercase and lowercase ASCII letters, numbers, underscores, and 
# hyphens, and must be between 1 and 200 characters long.
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

variable "display_name" {
  description = "The human-readable name used in the From field for notifications to email and email-json endpoints"
  type        = string
  nullable    = true
}

variable "encryption_kms_key_id" {
  description = <<EOF
  The ARN of the KMS key to use for server-side encryption. If not provided,
  the default AWS managed key 'alias/aws/sns' will be used.
  EOF
  type        = string
  default     = "alias/aws/sns"
  nullable    = false
  validation {
    condition     = length(var.encryption_kms_key_id) > 0
    error_message = "The KMS encryption key identifier must be non-empty."
  }
}

variable "policy" {
  description = <<EOF
  (Optional) The JSON policy for the SQS queue.
  EOF
  type        = string
  nullable    = true
  default     = null
}
