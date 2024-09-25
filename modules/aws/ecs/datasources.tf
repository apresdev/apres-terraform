# Lookup private and public subnets for the VPC. This gets back a list of subnet IDs.
data "aws_subnets" "private" {
  tags = {
    environment = var.vpc_environment_tag
    subnet-tier = "private"
  }
}
data "aws_subnets" "public" {
  tags = {
    environment = var.vpc_environment_tag
    subnet-tier = "public"
  }
}

# Now get the details for each subnet we found so we can get the CIDR blocks.
# This gets back the full details for each subnet, like the DescribeSubnets API call.
# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  tags = {
    Name        = "Workload VPC ${var.vpc_environment_tag}",
    environment = var.vpc_environment_tag
  }
}

locals {
  # ARM64 = Graviton = aarch64
  ami_pattern = var.container_cpu_architecture == "X86_64" ? "al2023-ami-ecs-hvm-2023*-x86_64" : "al2023-ami-ecs-hvm-2023*-arm64"
}

data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = [local.ami_pattern]
  }

  owners = ["amazon"]
}