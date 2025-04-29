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

variable "make_volume" {
  description = "Make a volume for the EC2 instances"
  type        = bool
  default     = false
}

variable "vpc_environment_tag" {
  description = "Environment tag for the VPC. CICD requires Test, developers should use Dev"
  type        = string
  default     = "Test"
}

variable "create_secret" {
  description = "Create a secret for the service to consume"
  type        = bool
}
