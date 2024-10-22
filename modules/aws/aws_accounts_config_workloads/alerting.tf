locals {
  # Create Chatbot if the specified region matches the current one
  enable_chat_alerts = var.chatbot_primary_region == data.aws_region.current.name ? true : false
}

# Setup cost management alerts, for both anomalies and budget alerts.
module "alerting" {
  count = local.enable_chat_alerts ? 1 : 0
  # Use remote source so we can keep versioning correctly, even though the module is in the same repo.
  #checkov:skip=CKV_TF_1: Explicitly using versions, not a hash.
  source              = "git@github.com:apresdev/apres-terraform.git//modules/aws/alerting?ref=rel/alerting/1.0.1"
  name                = "cloudwatchalarms"
  publishing_services = ["cloudwatch.amazonaws.com"]
  environment         = "Global"
  slack_workspace_id  = var.slack_workspace_id
  slack_channel_id    = var.slack_channel_id
  msteams_team_id     = var.msteams_team_id
  msteams_channel_id  = var.msteams_channel_id
  msteams_tenant_id   = var.msteams_tenant_id
  application         = "Alerting"
  component           = "Alerting"
  owner               = "Engineering"
}