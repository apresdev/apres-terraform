variable "environment" {
  description = "Environment name, used for tagging AWS resources, and in the bucket name."
  type        = string
  default     = "Dev"
  nullable    = false
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  default     = "Messaging"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  default     = "Messaging"
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

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
  nullable    = false
}
