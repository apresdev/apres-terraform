# Create the alerts if Slack or Teams channel id's are specified
locals {
  enable_chat_alerts = var.slack_channel_id != "" || var.msteams_channel_id != "" ? true : false
}

# Setup cost management alerts, for both anomalies and budget alerts.
module "alerting" {
  count = local.enable_chat_alerts ? 1 : 0
  # Use remote source so we can keep versioning correctly, even though the module is in the same repo.
  #checkov:skip=CKV_TF_1: Explicitly using versions, not a hash.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/alerting?ref=rel/alerting/2.1.1"
  name        = "costmanagement"
  environment = var.environment
  application = var.application
  component   = "Alerting"
  owner       = var.owner
  extra_tags  = var.extra_tags

  slack_workspace_id = var.slack_workspace_id
  chatbot_slack_config = var.slack_channel_id == "" ? [] : [
    {
      name                = "costmanagement"
      publishing_services = ["costalerts.amazonaws.com", "budgets.amazonaws.com"]
      slack_channel_id    = var.slack_channel_id
    }
  ]

  msteams_team_id   = var.msteams_team_id
  msteams_tenant_id = var.msteams_tenant_id
  chatbot_msteams_config = var.msteams_channel_id == "" ? [] : [
    {
      name                = "costmanagement"
      publishing_services = ["costalerts.amazonaws.com", "budgets.amazonaws.com"]
      msteams_channel_id  = var.msteams_channel_id
    }
  ]
}