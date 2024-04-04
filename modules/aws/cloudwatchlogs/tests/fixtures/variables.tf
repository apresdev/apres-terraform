variable "name" {
  description = "Description name of the CloudWatch Logs Group"
  type        = string
}

variable "path" {
  description = "Path of the CloudWatch Logs Group"
  type        = string
}

variable "retention_in_days" {
  description = "Retention in days"
  type        = number
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "example"
}