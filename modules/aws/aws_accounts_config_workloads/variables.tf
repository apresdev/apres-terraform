variable "enable_api_gateway_logging" {
  description = <<EOF
    Enable API Gateway logging to CloudWatch Logs. This requires an IAM Role and an API Gateway
    configuration per region. By default this is disabled, enable if you are planning to
    use API Gateway in the account this is deployed in.
  EOF
  type        = bool
  default     = false
}

variable "retain_load_balancer_logs_days" {
  description = <<EOF
    Number of days to retain the load balancer logs in the S3 bucket. By default, this is set to 365.
    Setting this to -1 will retain logs indefinitely.
  EOF
  type        = number
  default     = 365
}

variable "chatbot_primary_region" {
  description = <<EOF
    ChatBot will send CloudWatch Alarms to Slack or Teams (if configured) but ChatBot is a global service. Set this
    to the region name, like "us-east-2" or "us-west-2" where the primary ChatBot is configured.

    ChatBot must be configured in each account before being deployed, with Slack and/or Teams integration. See the
    instructions in the Apres `alerting` terraform module for more information.

    Leaving this blank will disable ChatBot, and the Slack and Teams variables will be ignored.
  EOF
  type        = string
  default     = ""
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

variable "slack_channel_id" {
  description = <<EOF
  The Slack channel ID for notifications. To find a channel ID, in Slack, right click on a channel
  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N
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

variable "msteams_channel_id" {
  description = <<EOF
    The Microsoft Teams Channel ID for nofications.  The Channel Id is buried in the URL to the channel,
    and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like
    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`
    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i
    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.
    EOF
  type        = string
  default     = ""
}

variable "msteams_tenant_id" {
  description = <<EOF
    The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console.
    EOF
  type        = string
  default     = ""
}

variable "email_addresses" {
  description = <<EOF
    List of email addresses to send notifications to.
    EOF
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for x in var.email_addresses : can(regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", x))])
    error_message = "Email addresses must be valid."
  }
}