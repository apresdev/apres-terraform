variable "monitoring_account_id" {
  description = <<EOF
        The AWS account ID of the monitoring account. This account will be granted access to
        view CloudWatch metrics, alarms and logs.
    EOF
  type        = string
  default     = ""
  validation {
    condition     = can(regex("^$|^[0-9]{12}$", var.monitoring_account_id))
    error_message = "monitoring_account_id must either be a 12 digit AWS account ID, or an empty string."
  }
}