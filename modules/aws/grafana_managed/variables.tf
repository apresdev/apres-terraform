variable "name" {
  description = "Name used to create resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  default     = "Observability"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  default     = "Grafana"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "environment" {
  description = "Environment Name, used for naming and tagging AWS resources."
  type        = string
  default     = "Global"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}

variable "admin_users" {
  description = "List of User IDs that should have ADMIN access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.admin_users : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x))])
    error_message = "User IDs must be UUIDs."
  }
}

variable "editor_users" {
  description = "List of User IDs that should have EDITOR access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.editor_users : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x))])
    error_message = "User IDs must be UUIDs."
  }
}

variable "viewer_users" {
  description = "List of User IDs that should have VIEWER access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.viewer_users : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x))])
    error_message = "User IDs must be UUIDs."
  }
}

variable "admin_groups" {
  description = "List of Group IDs that should have ADMIN access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.admin_groups : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x))])
    error_message = "Group IDs must be UUIDs."
  }
}

variable "editor_groups" {
  description = "List of Group IDs that should have EDITOR access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.editor_groups : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x))])
    error_message = "Group IDs must be UUIDs."
  }
}

variable "viewer_groups" {
  description = "List of Group IDs that should have VIEWER access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.viewer_groups : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x))])
    error_message = "Group IDs must be UUIDs."
  }
}

variable "accounts" {
  description = <<EOF
    AWS Account IDs that Grafana should have access to. The key is the display name and will
    be used as when creating the data source, in practice this should match the account name.
  EOF
  type        = map(string)
  validation {
    condition     = alltrue([for x in var.accounts : can(regex("^[0-9]{12}$", x))])
    error_message = "Account IDs must be 12 digits long."
  }
}

variable "deployed_account" {
  description = <<EOF
    The 12 digit AWS Account ID where the module is deployed. In certain cases the module
    used to create the S3 buckets used in this stack will defer looking up the account until the
    apply phase, causing the bucket to be marked for replacement, which will result in data loss.
    The only workaround is to specify the account id where the stack is deployed here.
  EOF
  type        = string
  validation {
    condition     = can(regex("^\\d{12}$", var.deployed_account))
    error_message = "The account_id must be exactly 12 digits."
  }
}

variable "deployed_region" {
  description = <<EOF
    The AWS Region, like `us-east-2` where the module is deployed. In certain cases the module
    used to create the S3 buckets used in this stack will defer looking up the region until the
    apply phase, causing the bucket to be marked for replacement, which will result in data loss.
    The only workaround is to specify the region here.
  EOF
  type        = string
}

variable "regions" {
  description = <<EOF
    List of regions in which Grafana should look for CloudWatch alarms.
    The current region will be added to the list if it is not already present.
  EOF
  type        = list(string)
}

variable "custom_cloudwatch_metrics_namespaces" {
  description = <<EOF
    List of custom namespaces in CloudWatch to be added to the CloudWatch data sources.
    If they are not added, the dashboards will not be able to search for metrics in these namespaces.
    The standard Apres namespaces will be added automatically.
  EOF
  type        = list(string)
  default     = []
}

variable "custom_dashboard_folder_name" {
  description = <<EOF
    Name of the folder where custom dashboards will be uploaded. This will be used both in S3
    as the intermediary storage, and in Grafana as the folder name."
  EOF
  type        = string
  default     = "Custom"
}

variable "custom_dashboards" {
  description = <<EOF
    List of custom dashboards to be added to Grafana. The key is the display name and the value is the
    path to the file containing the dashboard. JSON. The dashboards will be uploaded to the folder
    name specified in `custom_dashboard_folder_name`.
  EOF
  type        = map(string)
  default     = {}
}

variable "alert_email_addresses" {
  description = <<EOF
    A list of email addresses to subscribe to the default Grafana Alerts SNS Topic.

    NOTE: This does not automatically send all alerts to these email addresses, there are two
    manual steps to take, see the [Notifying on Alerts](#notifying-on-alerts) section for more information.
  EOF
  type        = list(string)
  default     = []
}