resource "aws_grafana_workspace" "default" {
  name        = local.name
  description = local.name

  account_access_type       = "CURRENT_ACCOUNT"
  authentication_providers  = ["AWS_SSO"]
  permission_type           = "CUSTOMER_MANAGED" # TODO:is this valid? Not sure, it might not be.
  grafana_version           = "10.4"
  data_sources              = ["CLOUDWATCH"]
  notification_destinations = ["SNS"]
  role_arn                  = aws_iam_role.grafana.arn

  # Allow admins in Grafana to manage plugins.
  # Unified alerting is the only alerting supported in later Grafana versions, so use that.
  configuration = jsonencode({
    "plugins" : {
      "pluginAdminEnabled" : true
    },
    "unifiedAlerting" : {
      "enabled" : true
    }
  })

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

resource "aws_grafana_role_association" "admin" {
  count        = length(var.admin_users) + length(var.admin_groups) > 0 ? 1 : 0
  role         = "ADMIN"
  user_ids     = length(var.admin_users) > 0 ? var.admin_users : null
  group_ids    = length(var.admin_groups) > 0 ? var.admin_groups : null
  workspace_id = aws_grafana_workspace.default.id
}

resource "aws_grafana_role_association" "editor" {
  count        = length(var.editor_users) + length(var.editor_groups) > 0 ? 1 : 0
  role         = "EDITOR"
  user_ids     = length(var.editor_users) > 0 ? var.editor_users : null
  group_ids    = length(var.editor_groups) > 0 ? var.editor_groups : null
  workspace_id = aws_grafana_workspace.default.id
}

resource "aws_grafana_role_association" "viewer" {
  count        = length(var.viewer_users) + length(var.viewer_groups) > 0 ? 1 : 0
  role         = "VIEWER"
  user_ids     = length(var.viewer_users) > 0 ? var.viewer_users : null
  group_ids    = length(var.viewer_groups) > 0 ? var.viewer_groups : null
  workspace_id = aws_grafana_workspace.default.id
}

# Create a service account for the Lambda Configurator to use
resource "aws_grafana_workspace_service_account" "default" {
  name         = "lambdaconfigurator"
  grafana_role = "ADMIN"
  workspace_id = aws_grafana_workspace.default.id
}

# Add a token for the service account, to store in the SSM parameter which the Lambda will read
resource "aws_grafana_workspace_service_account_token" "default" {
  # since there's an expiry on the token, we need to recreate it every time
  # we apply, so we do so by adding a timestamp to the name, forcing terraform
  # to replace the resource.
  name               = "lambdaconfigurator${timestamp()}"
  service_account_id = aws_grafana_workspace_service_account.default.service_account_id
  workspace_id       = aws_grafana_workspace.default.id
  seconds_to_live    = 2592000 # 30 days
}

resource "aws_ssm_parameter" "grafana_config" {
  #checkov:skip=CKV_AWS_337:"Ensure SSM parameters are using KMS CMK"
  name        = local.ssm_parameter_name
  description = "Apres Grafana Configuration"
  type        = "SecureString"
  value       = aws_grafana_workspace_service_account_token.default.key
  tags = merge(
    local.tags,
    {
      Name = local.ssm_parameter_short_name
    },
  )
}