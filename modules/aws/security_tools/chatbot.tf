# Create a guardrail policy, this is what the Chatbot can do when a user queries it, from Slack or Teams.
# Only create it if one of the two is set. In our case we only want to be able to respond to
# Security Hub events.
resource "aws_iam_policy" "chatbot_guardrails" {
  #checkov:skip=CKV_AWS_290:Constraints do not make sense in this case, wildcard resource is needed.
  #checkov:skip=CKV_AWS_355:Constraints do not make sense in this case, wildcard resource is needed.
  count       = ((var.slack_workspace_id != "" || var.msteams_team_id != "") && var.allow_chatbot_update_findings) ? 1 : 0
  name        = "ChatBot-Guardrails-Policy"
  description = "Policy for ChatBot to respond to queries"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "securityhub:BatchUpdateFindings",
            "securityhub:UpdateFindings" // deprecated but included for completeness
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
  })
}

locals {
  # If allow_chatbot_update_findings == true add the above policy to allow update findings, else just ReadOnly
  guardrail_policies = var.allow_chatbot_update_findings ? [aws_iam_policy.chatbot_guardrails[0].arn, "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"] : ["arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"]
}

resource "awscc_chatbot_slack_channel_configuration" "security_hub" {
  count              = var.slack_workspace_id != "" ? 1 : 0
  configuration_name = "securityhub-slack-channel-config"
  iam_role_arn       = awscc_iam_role.security_hub_slack[0].arn
  slack_channel_id   = var.slack_security_hub_events_channel_id
  slack_workspace_id = var.slack_workspace_id
  sns_topic_arns     = [aws_sns_topic.security_hub.arn]
  logging_level      = "INFO"
  guardrail_policies = local.guardrail_policies
}

resource "awscc_iam_role" "security_hub_slack" {
  count     = var.slack_workspace_id != "" ? 1 : 0
  role_name = "ChatBot-Slack-SecurityHub-Channel-Role"
  assume_role_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })
}

resource "awscc_chatbot_microsoft_teams_channel_configuration" "security_hub" {
  count              = (var.msteams_team_id != "") ? 1 : 0
  configuration_name = "securityhub-msteams-channel-config"
  iam_role_arn       = awscc_iam_role.security_hub_msteams[0].arn
  sns_topic_arns     = [aws_sns_topic.security_hub.arn]
  team_id            = var.msteams_team_id
  teams_channel_id   = var.msteams_channel_id
  teams_tenant_id    = var.msteams_tenant_id
  logging_level      = "INFO"
  guardrail_policies = local.guardrail_policies
}

resource "awscc_iam_role" "security_hub_msteams" {
  count     = (var.msteams_team_id != "") ? 1 : 0
  role_name = "ChatBot-MSTeams-SecurityHub-Channel-Role"
  assume_role_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })
}