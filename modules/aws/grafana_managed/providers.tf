terraform {
  required_version = ">= 1.6.0, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.21.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.2.1"
    }
  }
}