# This grants the permissions the lambda needs during execution
data "aws_iam_policy_document" "default" {

  policy_id = "${local.name}-stream-publisher"

  # Allows the lambda to publish to SNS
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [var.topic_arn]
  }

  # Allows the lambda to connect to the dynamodb stream
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams"
    ]

    resources = [
      var.stream_arn
    ]

  }

  # Allows the lambda to use the messaging key
  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [data.aws_kms_alias.messaging.target_key_arn]

  }

  depends_on = [data.aws_kms_alias.messaging]
}

# Attaches the additional lambda permissions to the policy
resource "aws_iam_role_policy" "default" {
  name_prefix = local.name
  role        = module.lambda.iam_role_name
  policy      = data.aws_iam_policy_document.default.json
}
