variable "name" {
  description = "Name used to create resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
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

variable "aws_account_id" {
  description = "Twelve digit AWS Account ID. If not set, the current account will be used."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS Region. If not set, the current region will be used."
  type        = string
  default     = ""
}