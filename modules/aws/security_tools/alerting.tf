locals {
  alerting_enabled = var.slack_security_hub_events_channel_id != "" || var.msteams_channel_id != ""
}

module "alerting" {
  count = local.alerting_enabled ? 1 : 0
  # Use remote source so we can keep versioning correctly, even though the module is in the same repo.
  #checkov:skip=CKV_TF_1: Explicitly using versions, not a hash.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/alerting?ref=rel/alerting/2.1.3"
  name        = "securityhub"
  environment = var.environment
  application = var.application
  component   = "Alerting"
  owner       = var.owner
  extra_tags  = var.extra_tags

  slack_workspace_id = var.slack_workspace_id
  chatbot_slack_config = var.slack_security_hub_events_channel_id == "" ? [] : [
    {
      name                = "securityhub"
      publishing_services = ["events.amazonaws.com"]
      slack_channel_id    = var.slack_security_hub_events_channel_id
    }
  ]

  msteams_team_id   = var.msteams_team_id
  msteams_tenant_id = var.msteams_tenant_id
  chatbot_msteams_config = var.msteams_channel_id == "" ? [] : [
    {
      name                = "securityhub"
      publishing_services = ["events.amazonaws.com"]
      msteams_channel_id  = var.msteams_channel_id
    }
  ]
}
