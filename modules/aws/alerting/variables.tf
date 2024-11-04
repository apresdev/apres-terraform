
variable "name" {
  description = "Name appended to the SNS topic, and used to identify other resources."
  type        = string
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources."
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
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  default     = "Alerting"
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

variable "environment" {
  description = "Environment Name, used for naming and tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."

  }
}

variable "slack_workspace_id" {
  description = <<EOF
  The Slack workspace ID for notifications,
  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it.

  If not set, Slack integration will not be enabled.
  EOF
  type        = string
  default     = ""
}

variable "msteams_team_id" {
  description = <<EOF
    The Microsoft Teams "Team ID" for notifications. This is displayed in the AWS Console. If not set,
    Teams integration will not be enabled.
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

variable "chatbot_slack_config" {
  description = <<EOF
    A list of configuration objects for Slack channels. See the "Channel Configuration" section
    in the README for more details.

    The SNS topic names will be prefixed with "apres-alerting-" and postfixed with the name.
  EOF
  default     = []
  type = list(object({
    name                = string
    publishing_services = list(string)
    slack_channel_id    = string
  }))
  validation {
    condition     = alltrue([for c in var.chatbot_slack_config : length(c.publishing_services) > 0])
    error_message = "Must specify at least one publishing_service."
  }
  validation {
    condition     = alltrue([for c in var.chatbot_slack_config : c.name != ""])
    error_message = "Must specify a name."
  }
  validation {
    condition     = alltrue([for c in var.chatbot_slack_config : c.slack_channel_id != ""])
    error_message = "Must specify a name."
  }
}

variable "chatbot_msteams_config" {
  description = <<EOF
    A list of configuration objects for Slack channels. See the "Channel Configuration" section
    in the README for more details.

    The SNS topic names will be prefixed with "apres-alerting-" and postfixed with the name.
  EOF
  default     = []
  type = list(object({
    name                = string
    publishing_services = list(string)
    msteams_channel_id  = string
  }))
  validation {
    condition     = alltrue([for c in var.chatbot_msteams_config : length(c.publishing_services) > 0])
    error_message = "Must specify at least one publishing_service."
  }
  validation {
    condition     = alltrue([for c in var.chatbot_msteams_config : c.name != ""])
    error_message = "Must specify a name."
  }
  validation {
    condition     = alltrue([for c in var.chatbot_msteams_config : c.msteams_channel_id != ""])
    error_message = "Must specify a name."
  }
}