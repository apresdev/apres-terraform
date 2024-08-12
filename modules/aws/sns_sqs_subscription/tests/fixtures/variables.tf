variable "name" {
  description = "Name of the table"
  type        = string
  validation {
    condition     = length(var.name) >= 3 && length(var.name) < 255
    error_message = "Name length must be between 3 and 255 characters."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-\\.]*$", var.name))
    error_message = "The name only contain letters, numbers, underscores, hyphens, and dots."
  }
}


variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "unittest"
}
