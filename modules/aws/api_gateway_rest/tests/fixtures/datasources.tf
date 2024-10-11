# Lookup private and public subnets for the VPC. This gets back a list of subnet IDs.
data "aws_subnets" "private" {
  tags = {
    environment = var.vpc_environment_tag
    subnet-tier = "private"
  }
}