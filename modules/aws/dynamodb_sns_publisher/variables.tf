variable "name" {
  description = <<EOF
  The name used to generate the SNS publisher resources (i.e. the lambda naming).
  EOF
  nullable    = false
  type        = string
}

variable "stream_arn" {
  description = <<EOF
  The ARN of the DynamoDB stream acting as the event source.
  EOF
  nullable    = false
  type        = string
}

variable "topic_arn" {
  description = <<EOF
  The ARN of the SNS topic acting as the event sink.
  EOF
  nullable    = false
  type        = string
}

# #########################################################################################################################################
# Regional Lambda variables
# #########################################################################################################################################
variable "lambda_regional_environment" {
  description = "Lambda Regional Environment Name, used to lookup regional code signing and S3 buckets."
  type        = string
  default     = "WorkLoadConfig"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.lambda_regional_environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}


# BEGIN_COMMON_VARS
variable "environment" {
  description = "Environment name, used for tagging AWS resources, and in the bucket name."
  type        = string
  default     = "dev"
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
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
# END_COMMON_VARS
