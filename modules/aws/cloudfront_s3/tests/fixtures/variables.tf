variable "name" {
  description = "Name of the distribution"
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