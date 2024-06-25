# Create the alerts if Slack or Teams channel id's are specified
locals {
  enable_chat_alerts = var.slack_channel_id != "" || var.msteams_channel_id != "" ? true : false
}

# Setup cost management alerts, for both anomalies and budget alerts.
module "alerting" {
  count               = local.enable_chat_alerts ? 1 : 0
  source              = "../alerting"
  name                = "costmanagement"
  publishing_services = ["costalerts.amazonaws.com", "budgets.amazonaws.com"]
  environment         = var.environment
  slack_workspace_id  = var.slack_workspace_id
  slack_channel_id    = var.slack_channel_id
  msteams_team_id     = var.msteams_team_id
  msteams_channel_id  = var.msteams_channel_id
  msteams_tenant_id   = var.msteams_tenant_id
  application         = var.application
  component           = "Alerting"
  owner               = var.owner
  extra_tags          = var.extra_tags
}