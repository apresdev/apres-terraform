variable "name" {
  description = "Name of the bucket"
  type        = string
  validation {
    condition     = length(var.name) >= 3 && length(var.name) < 24
    error_message = "Name length must be between 3 and 34 characters."
  }
  validation {
    condition     = can(regex("^[a-z-0-9][a-z0-9-]*[a-z-0-9]$", var.name))
    error_message = "The name must start with a letter or number, end with a letter or number, and can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "unittest"
}