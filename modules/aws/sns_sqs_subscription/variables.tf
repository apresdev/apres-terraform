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

variable "sns_topic_arn" {
  description = <<EOF
  The AWS ARN of the SNS topic to subscribe to.
  EOF
  type        = string
  nullable    = false
}

variable "sqs_queue_arn" {
  description = <<EOF
  The AWS ARN of the SQS subscriber queue.
  EOF
  type        = string
  nullable    = false
}

variable "sqs_queue_url" {
  description = <<EOF
  The URL of the SQS subscriber queue.
  EOF
  type        = string
  nullable    = false
}

variable "raw_message_delivery" {
  description = <<EOF
  (Optional) Whether to enable raw message delivery (the original message is directly passed, not wrapped in JSON with the original message in the message property). Default is true.
  EOF
  type        = bool
  default     = true
}