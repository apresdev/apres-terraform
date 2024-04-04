variable "audit_account_id" {
  # String because it can have leading zeros
  type        = string
  description = "The AWS account ID of the Audit account, which will be used to delegate configuration of the Security Tools"
  validation {
    condition     = length(var.audit_account_id) == 12
    error_message = "The Audit account ID must be 12 characters long"
  }
  validation {
    condition     = can(regex("^[0-9]*$", var.audit_account_id))
    error_message = "Audit account ID must only contain digits"
  }
}
