data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  tags = {
    Name        = "Workload VPC ${var.vpc_environment_tag}",
    environment = var.vpc_environment_tag
  }
}

data "aws_subnets" "private" {
  tags = {
    environment = var.vpc_environment_tag
    subnet-tier = "private"
  }
}