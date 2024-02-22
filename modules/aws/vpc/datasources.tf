# Get the AZ's.
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the lastest fck-net.dev AMI
data "aws_ami" "fck_nat" {
  filter {
    name   = "name"
    values = ["fck-nat-amzn2-*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  owners      = ["568608671756"]
  most_recent = true
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
