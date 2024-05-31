
variable "name" {
  description = "Name prepended to the SNS topic"
  type        = string
}

variable "default_tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default = {
    "application" = "FinOps"
    "owner"       = "Engineering"
    "managed-by"  = "terraform"
  }
}

variable "environment" {
  description = "Environment Name, used for tagging AWS resources."
  type        = string
  default     = "Root"
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
  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N
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

variable "publishing_services" {
  description = <<EOF
    A list of AWS services which are granted access to publish to the SNS topic. The topic is created with encryption
    enabled, and the services need to be granted access to publish to the topic using the key. For example:
    ["events.amazonaws.com", "health.amazonaws.com", "config.amazonaws.com", "trustedadvisor.amazonaws.com"]

    "events.amazonaws.com" is for EventBridge (CloudWatch Events), and "costalerts.amazonaws.com" is for Budget
    and Cost Anomaly alerts.
  EOF
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.publishing_services) > 0
    error_message = "At least one service must be set."
  }
}

variable "chatbot_policy_arns" {
  description = <<EOF
    An AWS IAM Policy ARNs to attach to the Chatbot. The policies should contain the necessary
    permissions for the Chatbot to interact with the services. For example:
    ["arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"]

    This policy gives the users in your channels permission to access AWS resources, so take care to
    limit what is granted.

    If no policy ARN is given, a default empty policy is set, granting only sts:GetCallerIdentity permission.

  EOF
  type        = list(string)
  default     = []
}