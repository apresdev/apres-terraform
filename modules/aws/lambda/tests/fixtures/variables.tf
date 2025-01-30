variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "enable_vpc" {
  type = bool
}

variable "vpc_environment_tag" {
  type    = string
  default = "Test"
}