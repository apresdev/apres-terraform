variable "name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "UnitTestEnv"
}

variable "application" {
  type    = string
  default = "UnitTestApp"
}

variable "component" {
  type    = string
  default = "UnitTestComp"
}

variable "vpc_environment_tag" {
  type    = string
  default = "Test"
}