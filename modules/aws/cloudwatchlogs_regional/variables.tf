variable "environment" {
  description = "Environment Name, used for tagging AWS resources."
  type        = string
  default     = "Dev"
}

variable "default_tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default = {
    "component"   = "cloudwatchlogs"
    "application" = "cloudwatchlogs"
    "owner"       = "Engineering"
    "managed-by"  = "terraform"
  }
}