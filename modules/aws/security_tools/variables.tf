variable "security_hub_linking_mode" {
  description = <<EOF
    One of ALL_REGIONS_EXPECT_SPECIFIED, SPECIFIED_REGIONS, or ALL_REGIONS. If you have an SCP restricting regions, then
    you must use ALL_REGIONS_EXPECT_SPECIFIED or SPECIFIED_REGIONS. If you do not have an SCP restricting regions, then
    you can use ALL_REGIONS, and leave security_hub_regions empty.

    The recommended approach is to have Control Tower govern only the regions you want to use. Control Tower will enable
    AWS Config in those regions, which is required by Security Hub. Then specify the supported regions in the security_hub_regions
    variable.
    EOF
  type        = string
  default     = "ALL_REGIONS"
  validation {
    condition     = can(index(["ALL_REGIONS_EXPECT_SPECIFIED", "SPECIFIED_REGIONS", "ALL_REGIONS"], var.security_hub_linking_mode))
    error_message = "security_hub_linking_mode must be one of ALL_REGIONS_EXPECT_SPECIFIED, SPECIFIED_REGIONS, or ALL_REGIONS"
  }
}

variable "security_hub_regions" {
  description = <<EOF
    A list of regions to link to the Security Hub master account. If you have an SCP restricting regions, then you must
    specify the regions here. If you do not have an SCP restricting regions, then you can leave this empty.
    EOF
  type        = list(string)
  default     = []
}

variable "guardduty_enable_s3_protection" {
  description = "Enable GuardDuty to monitor S3 buckets"
  type        = bool
  default     = true
}

variable "guardduty_enable_eks_protection" {
  description = "Enable GuardDuty to monitor EKS clusters"
  type        = bool
  default     = true
}

# Not supported yet, there's a manual setting in the management account that needs to get set somehow.
# variable "guardduty_enable_malware_protection" {
#   description = "Enable GuardDuty to monitor EBS volumes for malware.""
#   type        = bool
#   default     = true
# }

variable "guardduty_enable_rds_protection" {
  description = "Enable GuardDuty to monitor RDS instances"
  type        = bool
  default     = true
}

variable "guardduty_enable_lambda_protection" {
  description = "Enable GuardDuty to monitor Lambda functions"
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default = {
    "component"   = "securitytools"
    "application" = "securitytools"
    "owner"       = "Engineering"
    "managed-by"  = "terraform"
  }
}

variable "environment" {
  description = "Environment Name, used for tagging AWS resources."
  type        = string
  default     = "Dev"
}

variable "slack_workspace_id" {
  description = <<EOF
  The Slack workspace ID for Security Hub Findings,
  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it.
  EOF
  type        = string
  default     = ""
}

variable "slack_security_hub_events_channel_id" {
  description = <<EOF
  The Slack channel ID for Security Hub Events. To find a channel ID, in Slack, right click on a channel
  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N
  EOF
  type        = string
  default     = ""
}

variable "msteams_team_id" {
  description = <<EOF
    The Microsoft Teams Team ID for Security Hub Findings. This is displayed in the AWS Console"
    EOF
  type        = string
  default     = ""
}

variable "msteams_channel_id" {
  description = <<EOF
    The Microsoft Teams Channel ID for Security Hub Findings.
    The Channel Id is buried in the URL to the channel, and can be found in Teams using the "Get link to channel"
    menu option. A resulting URL might look like
    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`
    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i
    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.
    EOF
  type        = string
  default     = ""
}

variable "msteams_tenant_id" {
  description = <<EOF
    The Microsoft Teams Tenant ID for Security Hub Findings. This is displayed in the AWS Console"
    EOF
  type        = string
  default     = ""
}

variable "allow_chatbot_update_findings" {
  description = "Allow Chatbot to update findings. This applies to Slack and/or Teams."
  type        = bool
  default     = true
}