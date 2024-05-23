terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  # Chatbot is only supported in awscc so we include both.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.72.1"
    }
  }
}