variable "name" {
  description = "Name used to create resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
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
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
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

variable "instance_type" {
  description = "The instance type to use for the bastion host"
  type        = string
  default     = "t4g.nano"
}

variable "number_hosts" {
  description = <<EOF
    The number of bastion hosts to create, must be 1, 2, or 3. If greater than 1
    the hosts will be spread across availability zones.
    EOF
  type        = number
  default     = 1
  validation {
    condition     = can(index([1, 2, 3], var.number_hosts) != null)
    error_message = "Number of hosts must be 1, 2, or 3."
  }
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

variable "install_packages" {
  description = <<EOF
    A list of packages to install on the bastion host. The packages must be available in the
    Amazon Linux 2023 repositories, available
    [here](https://docs.aws.amazon.com/linux/al2023/release-notes/all-packages.html).
  EOF
  type        = list(string)
  default     = []
}
