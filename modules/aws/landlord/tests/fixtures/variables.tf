variable "domain" {
  type = string
}

variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_environment_tag" {
  description = <<EOF
    The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC
    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more
    if it was configured that way.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.vpc_environment_tag))
    error_message = "VPC Environment Tag must be alphanumeric and capitalized."
  }
}