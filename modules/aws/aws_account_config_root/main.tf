module "costmanagement" {
  #checkov:skip=CKV_TF_1: Not using a commit hash because we're using a tag
  source                      = "git@github.com:apresdev/apres-terraform.git//modules/aws/cost_management?ref=rel/cost_management/1.0.2"
  frequency                   = var.cost_anomaly_alerts_frequency
  anomaly_alert_on_dollars    = var.cost_anomaly_alert_on_dollars
  anomaly_alert_on_percentage = var.cost_anomaly_alert_on_percentage
  slack_workspace_id          = var.slack_workspace_id
  slack_channel_id            = var.slack_channel_id
  msteams_channel_id          = var.msteams_channel_id
  msteams_team_id             = var.msteams_team_id
  msteams_tenant_id           = var.msteams_tenant_id
  email_addresses             = var.cost_alerts_email_addresses
  cost_allocation_tags        = var.cost_allocation_tags
  budget_name                 = var.budget_name
  budget_limit                = var.budget_limit
  budget_alert_thresholds     = var.budget_alert_thresholds
}

locals {
  # Try get a list of possible accounts
  audit_accounts = [for account in data.aws_organizations_organization.default.accounts : account.id if lower(account.name) == "audit"]
  # If the account was given use it, else try look it up, fall back to null and the security_tools_delegator module will fail gracefully
  audit_account_id = var.audit_account_id != "" ? var.audit_account_id : (length(local.audit_accounts) > 0 ? local.audit_accounts[0] : "")
}

module "security_tools_delegator" {
  #checkov:skip=CKV_TF_1: Not using a commit hash because we're using a tag
  source           = "git@github.com:apresdev/apres-terraform.git//modules/aws/security_tools_delegator?ref=rel/security_tools_delegator/0.2.1"
  audit_account_id = local.audit_account_id
}

module "aws_accounts_global_config" {
  #checkov:skip=CKV_TF_1: Not using a commit hash because we're using a tag
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/aws_accounts_global_config?ref=rel/aws_accounts_global_config/0.1.0"
}