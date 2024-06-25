# If there are no policy arns or policy json defined, we need to create an empty statement else
# the guardrail will be set to Administrator. While this looks alarming, the actual access the Chatbot gets
# is an intersection of the role and the guardrail policy, but to prevent alarmed users we'll
# create an empty innocuous policy.
resource "aws_iam_policy" "chatbot_guardrails" {
  count       = length(var.chatbot_policy_arns) == 0 ? 1 : 0
  name_prefix = "ChatBot-Guardrails-${title(var.name)}-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EmptyPolicy"
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = ["*"]
      }
    ]
  })
  tags = merge(
    local.tags,
    {
      Name = "ChatBot-Guardrails-${title(var.name)}-${var.environment}"
    },
  )
}

data "aws_iam_policy_document" "chatbot_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
  }
}

# Create the Slack Configuration
# NOTE: Tags aren't supported at time of writing in this provider.
resource "awscc_chatbot_slack_channel_configuration" "default" {
  count              = var.slack_workspace_id != "" ? 1 : 0
  configuration_name = "${lower(var.name)}-${lower(var.environment)}-${var.slack_channel_id}"
  iam_role_arn       = aws_iam_role.slack[0].arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  sns_topic_arns     = [aws_sns_topic.default.arn]
  logging_level      = "INFO"
  guardrail_policies = length(var.chatbot_policy_arns) > 0 ? var.chatbot_policy_arns : [aws_iam_policy.chatbot_guardrails[0].arn]
}

resource "aws_iam_role" "slack" {
  count              = var.slack_workspace_id != "" ? 1 : 0
  name_prefix        = "${title(var.name)}-ChatBot-Slack-Channel"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role.json
  # include any arns if they are passed in
  managed_policy_arns = length(var.chatbot_policy_arns) > 0 ? var.chatbot_policy_arns : [aws_iam_policy.chatbot_guardrails[0].arn]
  tags = merge(
    local.tags,
    {
      Name = "${title(var.name)}-ChatBot-Slack-Channel"
    },
  )
}

# Create the Microsoft Teams Configuration
resource "awscc_chatbot_microsoft_teams_channel_configuration" "default" {
  count              = var.msteams_team_id != "" ? 1 : 0
  configuration_name = "${lower(var.name)}-${lower(var.environment)}-${var.msteams_channel_id}"
  iam_role_arn       = aws_iam_role.msteams[0].arn
  sns_topic_arns     = [aws_sns_topic.default.arn]
  team_id            = var.msteams_team_id
  teams_channel_id   = var.msteams_channel_id
  teams_tenant_id    = var.msteams_tenant_id
  logging_level      = "INFO"
  guardrail_policies = length(var.chatbot_policy_arns) > 0 ? var.chatbot_policy_arns : [aws_iam_policy.chatbot_guardrails[0].arn]
}

resource "aws_iam_role" "msteams" {
  count       = var.msteams_team_id != "" ? 1 : 0
  name_prefix = "${title(var.name)}-ChatBot-MSTeams-Channel"
  # include any arns if they are passed in
  assume_role_policy  = data.aws_iam_policy_document.chatbot_assume_role.json
  managed_policy_arns = length(var.chatbot_policy_arns) > 0 ? var.chatbot_policy_arns : [aws_iam_policy.chatbot_guardrails[0].arn]
  tags = merge(
    local.tags,
    {
      Name = "${title(var.name)}-ChatBot-MSTeams-Channel"
    },
  )
}