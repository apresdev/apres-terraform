terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
    }
  }
  # Allow 1.6 to 2.0
  required_version = ">= 1.7.0, < 2.0.0"
}
