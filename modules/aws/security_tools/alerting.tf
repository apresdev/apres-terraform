module "alerting" {
  source              = "../alerting"
  name                = "securityhub"
  publishing_services = ["events.amazonaws.com"]
  environment         = var.environment
  slack_workspace_id  = var.slack_workspace_id
  slack_channel_id    = var.slack_security_hub_events_channel_id
  msteams_team_id     = var.msteams_team_id
  msteams_channel_id  = var.msteams_channel_id
  msteams_tenant_id   = var.msteams_tenant_id
}