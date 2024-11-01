# Create the Slack Configuration
resource "aws_chatbot_slack_channel_configuration" "default" {
  for_each = { for idx, config in var.chatbot_slack_config : idx => config }
  # Include the region name so we can deploy this into multiple regions in the same account
  configuration_name = "${module.apres_names.local_name}-Slack-${data.aws_region.current.name}"
  logging_level      = "INFO"

  # Security - IAM Role and guardrail policy
  iam_role_arn          = aws_iam_role.slack[0].arn
  guardrail_policy_arns = [aws_iam_policy.chatbot_guardrails.arn]

  # Slack specific config
  slack_team_id    = var.slack_workspace_id
  slack_channel_id = each.value.slack_channel_id

  # Topic to subscribe to
  sns_topic_arns = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sns_topic_prefix}${each.value.name}"]

  tags = merge(
    local.tags,
    {
      Name = "${module.apres_names.local_name}-${data.aws_region.current.name}"
    },
  )
}

# Create the Microsoft Teams Configuration
resource "aws_chatbot_teams_channel_configuration" "default" {
  for_each           = { for idx, config in var.chatbot_msteams_config : idx => config }
  configuration_name = "${module.apres_names.local_name}-Teams-${data.aws_region.current.name}"
  logging_level      = "INFO"

  # Security - IAM Role and guardrail policy
  iam_role_arn          = aws_iam_role.msteams[0].arn
  guardrail_policy_arns = [aws_iam_policy.chatbot_guardrails.arn]

  # Teams specific config
  team_id    = var.msteams_team_id
  tenant_id  = var.msteams_tenant_id
  channel_id = each.value.msteams_channel_id

  # Topic to subscribe to
  sns_topic_arns = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sns_topic_prefix}${each.value.name}"]

  tags = merge(
    local.tags,
    {
      Name = "${module.apres_names.local_name}-${data.aws_region.current.name}"
    },
  )
}

resource "aws_iam_policy" "chatbot_guardrails" {
  name_prefix = "${module.apres_names.local_name}-ChatBot-Guardrails"
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
      Name = "${module.apres_names.local_name}-ChatBot"
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

# Create the roles for ChatBot to assume for Slack
resource "aws_iam_role" "slack" {
  count              = local.slack_enabled ? 1 : 0
  name_prefix        = "${module.apres_names.local_name}-ChatBot-Slack"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role.json
  tags = merge(
    local.tags,
    {
      Name = "${module.apres_names.local_name}-ChatBot-Slack"
    },
  )
}

resource "aws_iam_role_policy_attachment" "slack" {
  count      = local.slack_enabled ? 1 : 0
  role       = aws_iam_role.slack[0].name
  policy_arn = aws_iam_policy.chatbot_guardrails.arn
}

# Create the roles for ChatBot to assume for Teams
resource "aws_iam_role" "msteams" {
  count              = local.teams_enabled ? 1 : 0
  name_prefix        = "${module.apres_names.local_name}-ChatBot-Teams"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role.json
  tags = merge(
    local.tags,
    {
      Name = "${module.apres_names.local_name}-ChatBot-Teams"
    },
  )
}

resource "aws_iam_role_policy_attachment" "msteams" {
  count      = local.teams_enabled ? 1 : 0
  role       = aws_iam_role.msteams[0].name
  policy_arn = aws_iam_policy.chatbot_guardrails.arn
}