# Lookup private and public subnets for the VPC. This gets back a list of subnet IDs.
data "aws_subnets" "persistence" {
  tags = {
    environment = var.vpc_environment_tag
    subnet-tier = "persistence"
  }
}
data "aws_subnets" "private" {
  tags = {
    environment = var.vpc_environment_tag
    subnet-tier = "private"
  }
}

# Now get the details for each subnet we found so we can get the CIDR blocks.
# This gets back the full details for each subnet, like the DescribeSubnets API call.
# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnet" "persistence" {
  for_each = toset(data.aws_subnets.persistence.ids)
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
