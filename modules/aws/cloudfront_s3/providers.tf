terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
    }
  }
}

# Specify us-east-1 because a CloudFront WAF can only be created in us-east-1.
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}