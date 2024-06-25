
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
  default     = "FinOps"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
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
  default     = "Root"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."

  }
}

variable "frequency" {
  description = <<EOF
  Frequency of the alerts, one of DAILY, IMMEDIATE, or WEEKLY. Note that IMMEDIATE alerts are not supported for email
  subscriptions. If email addresses are supplied and frequency is set to IMMEDIATE, the email subscriptions will be
  set to DAILY. If email addresses are supplied and frequency is set to WEEKLY, the email subscriptions will be set to WEEKLY.
  EOF
  type        = string
  default     = "DAILY"
  validation {
    condition     = can(regex("^(DAILY|IMMEDIATE|WEEKLY)$", var.frequency))
    error_message = "Frequency must be one of DAILY, IMMEDIATE, or WEEKLY"
  }
}

variable "anomaly_alert_on_percentage" {
  description = <<EOF
    Alert if a Cost Anomaly is greater than or equal to this percentage. This condition will be combined with
    the anomaly_alert_on_dollars condition using an AND operator. Valid values can be more than 100%.
  EOF
  type        = number
  default     = 10
  validation {
    condition     = var.anomaly_alert_on_percentage > 0
    error_message = "Alert on percentage must be higher than 0."
  }
}

variable "anomaly_alert_on_dollars" {
  description = <<EOF
    Alert if a Cost Anomaly is greater than or equal to this dollar amount. This condition will be combined with
    the anomaly_alert_on_percentage condition using an AND operator.
  EOF
  type        = number
  default     = 100
  validation {
    condition     = var.anomaly_alert_on_dollars >= 0
    error_message = "Alert on dollars must be greater than or equal to 0."
  }
}

variable "slack_workspace_id" {
  description = <<EOF
  The Slack workspace ID for notifications,
  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it.
  EOF
  type        = string
  default     = ""
}

variable "slack_channel_id" {
  description = <<EOF
  The Slack channel ID for notifications. To find a channel ID, in Slack, right click on a channel
  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N. If left blank
  Slack integration will not be enabled.
  EOF
  type        = string
  default     = ""
}

variable "msteams_team_id" {
  description = <<EOF
    The Microsoft Teams Team ID for notifications. This is displayed in the AWS Console"
    EOF
  type        = string
  default     = ""
}

variable "msteams_channel_id" {
  description = <<EOF
    The Microsoft Teams Channel ID for notifications.  The Channel Id is buried in the URL to the channel,
    and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like
    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`
    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i
    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.

    If left blank, MS Teams integration will not be enabled.
    EOF
  type        = string
  default     = ""
}

variable "msteams_tenant_id" {
  description = <<EOF
    The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console"
    EOF
  type        = string
  default     = ""
}

variable "email_addresses" {
  description = <<EOF
    List of email addresses to send notifications to. At least one email address must be set.
    EOF
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.email_addresses : can(regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", x))])
    error_message = "Email addresses must be valid."
  }
}

variable "cost_allocation_tags" {
  description = <<EOF
    Set of Cost Allocation tags to be used for cost allocation. These tags become available in Cost Explorer and make
    reporting much easier.
    The default set of cost allocation tags here is what is used by Apres modules:
    * environment: Name of the environment, used to differentiate instances, like Dev, Test, Prod, etc.
    * application: Overall application name.
    * component: Component of an application
    * owner: Owner of the resource, typically Engineering but could be something else.
    * managed-by: Name of the tool managing the resources, usually Terraform but could be something else.
  EOF
  type        = list(string)
  default = [
    "environment",
    "application",
    "component",
    "owner",
    "managed-by"
  ]
}

variable "budget_name" {
  description = <<EOF
    The name of the default Budget. This name will be used to create the Budget in AWS and will be used in the
    alerts generated by the Budget.
  EOF
  type        = string
  default     = "Default Budget"
}

variable "budget_limit" {
  description = <<EOF
    The limit set for the default Budget, in USD, for monthly spend.  Alerts will be generated
    when the predicted or actual monthly spend exceeds this limit.

    The $ amount is the spend for all accounts in the organization. At this time budgets per account or tag groups are
    not supported yet.

  EOF
  type        = number
  default     = 100
}

variable "budget_alert_thresholds" {
  description = <<EOF
    The thresholds for budget alerts. Each item is a different alert. The "percent" is the percentage of the `budget_limit`
    variable, the value can be more than 100%. For example, you could set a threshold of 200% to alert when the spend is
    200% of the budget.

    The "type" is one of FORECASTED or ACTUAL.

    The default values are to alert when:
    * AWS Budgets forecasts 85% `budget_limit` will be reached
    * AWS Budgets forecasts 100% of the `budget_limit` will be reached
    * AWS Budgets calculates 85% of the `budget_limit` has been reached
    * AWS Budgets calculates 100% of the `budget_limit` has been reached

  EOF
  type = list(object({
    percent = number
    type    = string
  }))
  default = [
    { percent = 85, type = "FORECASTED" },
    { percent = 100, type = "FORECASTED" },
    { percent = 85, type = "ACTUAL" },
    { percent = 100, type = "ACTUAL" }
  ]
  validation {
    # Validate that all types are FORECASTED or ACTUAL
    condition = alltrue([
      for o in var.budget_alert_thresholds : o if !contains(["FORECASTED", "ACTUAL"], o["type"])
    ])
    error_message = "budget_alert_thresholds.type must be one of FORECASTED or ACTUAL"
  }
  validation {
    # Validate numbers are between 0 and 100
    condition = alltrue([
      for o in var.budget_alert_thresholds : o if o["percent"] < 0
    ])
    error_message = "budget_alert_thresholds.percent must be greater than zero"
  }
}
