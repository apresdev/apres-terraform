variable "company_name" {
  description = "Company name, required for the primary contact."
  type        = string
}

variable "company_address_line_1" {
  description = "Company address, required for the primary contact."
  type        = string
}

variable "company_address_line_2" {
  description = "Company address line 2 (optional), required for the primary contact."
  type        = string
  default     = ""
}

variable "company_city" {
  description = "Company city, required for the primary contact."
  type        = string
}

variable "company_country_code" {
  description = "Company country code, required for the primary contact."
  type        = string
  validation {
    condition     = can(regex("^[A-Z]{2}$", var.company_country_code))
    error_message = "Country code must be two uppercase letters."
  }
}

variable "company_state_or_region" {
  description = "Company State or Province or Region, required for the primary contact."
  type        = string
}


variable "primary_contact_full_name" {
  description = "Name of the primary contact, may be the same as given in the alternate contact info."
  type        = string
}

variable "primary_contact_phone_number" {
  description = <<EOF
  Phone number of the primay contact, may be the same as given in the alternate contact info.
  See https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-update-contact-primary.html#manage-acct-update-contact-primary-requirements
  for requirements of format.
  EOF
  type        = string
  validation {
    condition     = can(regex("^\\+[0-9 \\-]*$", var.primary_contact_phone_number))
    error_message = "Phone number must be valid format."

  }
}

variable "company_postal_code" {
  description = "Postal code or Zip code of the company, required for the primary contact."
  type        = string
}

variable "alternate_contact_info" {
  type = map(object({
    name          = string
    title         = string
    email_address = string
    phone_number  = string
  }))
  description = <<EOF
    Alternate contact information. The information provided will be set on all the AWS accounts in
    the AWS Organization.

    There are three types of alternate contacts in AWS: Operations, Security, and Billing.
    For simplicity they can all be set to the same values in this provider by setting `type`
    to the string `default`. Else a separate element should be set for each type of
    `operations`, `security`, and `billing`.

    Apres recommends the email address(es) to be a distribution list, not an individual's email address.
    These contacts are used by AWS to notify of security events and billing issues, and the
    email addresses given should be monitored. Failing to respond to security or billing events may result
    in termination of services.

    For example, setting all contacts to the same info:
      ```hcl
      module "organizations" {
        # ...
        alternate_contact_info = {
          "default" = {
            name          = "Micky McGuire"
            title         = "CEO"
            email_address = "micky.mcguire@acme.com"
            phone_number  = "+1 234-567-8901"
          }
        }
      }
      ```
    Or setting different contacts for each type:
      ```hcl
      module "organizations" {
        # ...
        alternate_contact_info = {
          "operations" = [
            {
              name          = "Micky McGuire"
              # omitted for brevity ...
            }
          ],
          "security" = [
            {
              name          = "Micky McGuire"
              # omitted for brevity ...
            }
          ],
          # ...
        }
      }
  EOF
}

variable "cost_anomaly_alerts_frequency" {
  description = <<EOF
  Frequency of the cost_anomaly alerts, one of DAILY, IMMEDIATE, or WEEKLY. Note that IMMEDIATE alerts are not supported for email
  subscriptions. If email addresses are supplied and frequency is set to IMMEDIATE, the email subscriptions will be
  set to DAILY. If email addresses are supplied and frequency is set to WEEKLY, the email subscriptions will be set to WEEKLY.
  EOF
  type        = string
  default     = "DAILY"
  validation {
    condition     = can(regex("^(DAILY|IMMEDIATE|WEEKLY)$", var.cost_anomaly_alerts_frequency))
    error_message = "Frequency must be one of DAILY, IMMEDIATE, or WEEKLY"
  }
}

variable "cost_anomaly_alert_on_percentage" {
  description = <<EOF
    Alert if a Cost Anomaly is greater than or equal to this percentage. This condition will be combined with
    the anomaly_alert_on_dollars condition using an AND operator. Valid values can be more than 100%.
  EOF
  type        = number
  default     = 10
  validation {
    condition     = var.cost_anomaly_alert_on_percentage > 0
    error_message = "Alert on percentage must be higher than 0."
  }
}

variable "cost_anomaly_alert_on_dollars" {
  description = <<EOF
    Alert if a Cost Anomaly is greater than or equal to this dollar amount. This condition will be combined with
    the anomaly_alert_on_percentage condition using an AND operator.
  EOF
  type        = number
  default     = 100
  validation {
    condition     = var.cost_anomaly_alert_on_dollars >= 0
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

variable "cost_alerts_email_addresses" {
  description = <<EOF
    List of email addresses to send notifications to. At least one email address must be set.
    EOF
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.cost_alerts_email_addresses : can(regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", x))])
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

variable "audit_account_id" {
  # String because it can have leading zeros
  type        = string
  default     = ""
  description = <<EOF
    The AWS account ID of the Audit account, which will be used to delegate configuration of the Security Tools. If not
    given the module will attempt to lookup the account by the case-insensitive name "audit" in the organization.
  EOF
}

variable "primary_region" {
  type        = string
  description = <<EOF
  The primary region where the AWS Organization is located, and where SecurityHub will be running in the audit account.
  EOF

}