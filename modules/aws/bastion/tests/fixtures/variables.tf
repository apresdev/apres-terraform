variable "name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "TestEnv"
}

variable "application" {
  type    = string
  default = "TestApplication"
}

variable "component" {
  type    = string
  default = "TestComp"
}

variable "vpc_environment_tag" {
  description = "Environment tag for the VPC. CICD requires Test, developers should use Dev"
  type        = string
  default     = "Test"
}