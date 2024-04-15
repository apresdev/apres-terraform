resource "aws_sns_topic" "security_hub" {
  name              = "security_hub_findings"
  kms_master_key_id = "alias/aws/sns"
  tags = merge(
    local.tags,
    {
      Name = "security_hub_findings"
    },
  )
}

resource "aws_sns_topic_policy" "security_hub" {
  arn    = aws_sns_topic.security_hub.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.security_hub.arn]
  }
}
