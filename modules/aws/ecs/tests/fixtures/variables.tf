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

variable "target" {
  description = "EC2 or FARGATE"
  type        = string
  validation {
    condition     = var.target == "EC2" || var.target == "FARGATE"
    error_message = "target must be either EC2 or FARGATE"
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type to use for the ECS cluster"
  type        = string
  default     = "t3.micro"
}

variable "ec2_use_instance_nvme_storage" {
  description = "Use NVMe storage for the EC2 instances"
  type        = bool
  default     = false
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

variable "container_port" {
  description = "Port to expose on the container, -1 means no port"
  type        = number
  default     = -1
}

variable "create_load_balancer" {
  description = "Create a load balancer for the service"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Type of load balancer to create"
  type        = string
}

variable "load_balancer_is_public" {
  description = "Is the load balancer public"
  type        = bool
}