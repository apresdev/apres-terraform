# Create a CMK Policy Document which permits SNS to send encrypted messages to SQS queues.
data "aws_iam_policy_document" "cmk" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [aws_kms_key.messaging.arn]
  }

  statement {
    sid     = "SNS decrypt permission"
    actions = ["kms:GenerateDataKey*", "kms:Decrypt"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    resources = [aws_kms_key.messaging.arn]
  }

  depends_on = [aws_kms_key.messaging]
}

# This is needed to allow SNS to send messages to an encrypted SQS queue.
# See: https://docs.aws.amazon.com/sns/latest/dg/sns-enable-encryption-for-topic-sqs-queue-subscriptions.html
resource "aws_kms_key" "messaging" {
  description             = "A CMK that is shared between messaging services (SNS and SQS)"
  enable_key_rotation     = true
  deletion_window_in_days = 20

  tags = merge(
    local.tags,
    tomap({
      Name = local.name
    })
  )
}

# Attach the policy to the CMK
resource "aws_kms_key_policy" "default" {
  key_id = aws_kms_key.messaging.id
  policy = data.aws_iam_policy_document.cmk.json

  depends_on = [data.aws_iam_policy_document.cmk]
}

# Give the CMK a messaging alias
resource "aws_kms_alias" "messaging" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.messaging.id

  depends_on = [aws_kms_key.messaging]
}
