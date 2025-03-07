resource "aws_sns_topic" "default" {
  name              = local.sns_topic_name
  display_name      = local.sns_topic_name
  kms_master_key_id = "alias/aws/sns"
  tags = merge(
    local.tags,
    {
      Name = local.sns_topic_name
    },
  )
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.default.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.default.arn]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_subscription" "default" {
  for_each  = toset(var.alert_email_addresses)
  topic_arn = aws_sns_topic.default.arn
  protocol  = "email"
  endpoint  = each.key
}
