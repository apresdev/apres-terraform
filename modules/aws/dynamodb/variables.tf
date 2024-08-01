variable "environment" {
  description = "Environment name, used for tagging AWS resources, and in the bucket name."
  type        = string
  default     = "dev"
}

# Table names and index names must be between 3 and 255 characters long, and can contain only the following characters:
#  - a-z
#  - A-Z
#  - 0-9
#  - _ (underscore)
#  - - (dash)
#  - . (dot)
variable "name" {
  description = "Name of the table, must be between 3 and 255 characters long and can contain only the following characters: a-z, A-Z, 0-9, _, -, and ."
  type        = string
  validation {
    condition     = length(var.name) >= 3 && length(var.name) < 255
    error_message = "Name length must be between 3 and 255 characters."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-\\.]*$", var.name))
    error_message = "The name only contain letters, numbers, underscores, hyphens, and dots."
  }
}

variable "table_class" {
  description = "(Optional) Storage class of the table. Valid values are STANDARD and STANDARD_INFREQUENT_ACCESS. Default value is STANDARD"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = var.table_class == "STANDARD" || var.table_class == "STANDARD_INFREQUENT_ACCESS"
    error_message = "The table_class must be one of STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "attributes" {
  description = <<EOF
  List of nested attribute definitions. Only required for hash_key and range_key attributes.
  Each attribute has two properties:
    name - (Required) The name of the attribute,
    type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data
  EOF
  type        = list(map(string))
  default     = []
}

variable "billing_mode" {
  description = <<EOF
  (Optional) Controls how you are charged for read and write throughput and how you manage capacity. The valid values are PROVISIONED and
  PAY_PER_REQUEST. Defaults to PROVISIONED.
  EOF
  type        = string
  default     = "PROVISIONED"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "The billing mode must be one of PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key. Must also be defined as an attribute"
  type        = string
  default     = null
  validation {
    condition     = length(var.hash_key) > 0
    error_message = "The hash_key must be non-empty."
  }
}

variable "range_key" {
  description = "(Optional) The attribute to use as the range (sort) key. Must also be defined as an attribute"
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Indicates whether ttl is enabled"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "(Optional) Name of the table attribute to store the TTL timestamp in. Required if ttl_enabled is true, must not be set otherwise."
  type        = string
  default     = ""
}

variable "deletion_protection_enabled" {
  description = "(Optional) Enables deletion protection for table. Defaults to true."
  type        = bool
  default     = true

}

variable "point_in_time_recovery_enabled" {
  description = <<EOF
  (Optional) Whether to enable Point In Time Recovery for the replica. Default is true.
  EOF
  type        = bool
  default     = true
}

variable "write_capacity" {
  description = <<EOF
  The number of write units for this table.
  If the billing_mode is PROVISIONED, then write_capacity should be greater than 0.
  EOF
  type        = number
  default     = 5
}

variable "read_capacity" {
  description = <<EOF
  The number of read units for this table.
  If the billing_mode is PROVISIONED, then read_capacity should be greater than 0.
  EOF
  type        = number
  default     = 5
}

variable "autoscaling_enabled" {
  description = "Flag indicating whether or not to enable autoscaling. Default is true"
  type        = bool
  default     = true
}

variable "autoscaling_defaults" {
  description = "A map of default autoscaling settings"
  type        = map(string)
  default = {
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
    target_value       = 70
  }
}

variable "autoscaling_read" {
  description = "A map of read autoscaling settings. `max_capacity` is the only required key.  Default is 1,000."
  type        = map(string)
  default = {
    max_capacity = 1000
  }
}

variable "autoscaling_write" {
  description = "A map of write autoscaling settings. `max_capacity` is the only required key.  Default is 1,000."
  type        = map(string)
  default = {
    max_capacity = 1000
  }
}

variable "autoscaling_indexes" {
  description = "A map of index autoscaling configurations."
  type        = map(map(string))
  default     = {}
}

variable "stream_enabled" {
  description = "Indicates whether Streams are to be enabled (true) or disabled (false)."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = <<EOF
  When an item in the table is modified, StreamViewType determines what information is written to the table's stream.
  EOF
  type        = string
  default     = null
  validation {
    condition     = contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "The stream_view_type must be one of KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, or NEW_AND_OLD_IMAGES."
  }
}

variable "encryption_kms_key_id" {
  description = <<EOF
  The ARN of the KMS key to use for server-side encryption. If not provided,
  the default AWS managed key 'aws/dynamodb' will be used.
  EOF
  type        = string
  default     = ""
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
