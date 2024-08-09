# This creates a default policy for the topic.
# The default policy only allows resources within the same account to publish or subscribe to the topic.
data "aws_iam_policy_document" "sns-topic-policy" {
  policy_id = "${local.topic_arn}/__default_policy_ID"

  statement {
    sid = "AllowAccount"

    effect = "Allow"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission"
    ]

    resources = [
      local.topic_arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        local.account_id,
      ]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

  }

  statement {
    sid = "AllowedServices"

    effect = "Allow"

    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
    ]

    condition {
      test     = "StringLike"
      variable = "SNS:Endpoint"

      values = [
        "arn:aws:sqs:${local.region}:${local.account_id}:*",
      ]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      local.topic_arn,
    ]

  }
}
