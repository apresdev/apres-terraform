variable "name" {
  description = "Name of the API Gateway"
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

variable "description" {
  description = "Description of the API Gateway, used for testing templating"
  type        = string
}

variable "timestamp" {
  description = "Timestamp used for testing the template"
  type        = string
}

variable "attach_vpc_load_balancer" {
  type    = bool
  default = false
}

variable "vpc_environment_tag" {
  description = "Environment tag for the VPC. CICD requires Test, developers should use Dev or Sandbox"
  type        = string
  default     = "Test"
}