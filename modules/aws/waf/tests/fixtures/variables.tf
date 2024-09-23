variable "name" {
  description = "Name of the WAF"
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
  default     = "Unittest"
}

variable "vpc_environment_tag" {
  description = <<EOF
    The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC
    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more
    if it was configured that way.
  EOF
  type        = string
  default     = "Sandbox"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.vpc_environment_tag))
    error_message = "VPC Environment Tag must be alphanumeric and capitalized."
  }
}