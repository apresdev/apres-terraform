locals {
  chatbot_slack_config = var.slack_workspace_id != "" ? [
    {
      name                = "cloudwatchalarms"
      publishing_services = ["cloudwatch.amazonaws.com"]
      slack_channel_id    = var.slack_channel_id
    }
  ] : []

  chatbot_msteams_config = var.msteams_team_id != "" ? [
    {
      name                = "cloudwatchalarms"
      publishing_services = ["cloudwatch.amazonaws.com"]
      msteams_channel_id  = var.msteams_channel_id
    }
  ] : []
}

module "alerting" {
  #checkov:skip=CKV_TF_1: Explicitly using versions, not a hash.
  source                 = "git@github.com:apresdev/apres-terraform.git//modules/aws/alerting?ref=rel/alerting/2.0.1"
  name                   = "cloudwatchalarms"
  environment            = "Alerting"
  application            = "Alerting"
  component              = "Alerting"
  owner                  = "Engineering"
  slack_workspace_id     = var.slack_workspace_id
  chatbot_slack_config   = local.chatbot_slack_config
  msteams_team_id        = var.msteams_team_id
  msteams_tenant_id      = var.msteams_tenant_id
  chatbot_msteams_config = local.chatbot_msteams_config
}