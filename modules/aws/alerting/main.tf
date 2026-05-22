locals {
  sns_key_alias = "alias/apres/alerting-${lower(var.name)}-${lower(var.environment)}-sns"
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application,
      "component"   = var.component,
      "owner"       = var.owner,
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )

  slack_enabled = var.slack_workspace_id != "" ? true : false
  teams_enabled = var.msteams_team_id != "" ? true : false

  # Create a flattened list of publishing services
  slack_publishing_services = distinct(flatten([for c in var.chatbot_slack_config : c.publishing_services]))
  teams_publishing_services = distinct(flatten([for c in var.chatbot_msteams_config : c.publishing_services]))
  all_publishing_services   = distinct(concat(local.slack_publishing_services, local.teams_publishing_services))

  # Create flattened list of SNS topics to create
  sns_topic_prefix = "apres-alerting-"
  slack_sns_topic_names = [
    for config in var.chatbot_slack_config : "${local.sns_topic_prefix}${config.name}"
  ]
  teams_sns_topic_names = [
    for config in var.chatbot_slack_config : "${local.sns_topic_prefix}${config.name}"
  ]
  all_sns_topic_names = distinct(concat(local.slack_sns_topic_names, local.teams_sns_topic_names))
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}