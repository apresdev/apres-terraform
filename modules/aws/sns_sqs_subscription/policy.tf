# This creates a default policy for the queue.
# The default policy only allows the SNS topic to send messages directly to the SQS queue.
data "aws_iam_policy_document" "default" {
  policy_id = "Grant SNS Access"

  statement {
    sid = "Grant SNS Access"
    actions = [
      "SQS:SendMessage"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      var.sqs_queue_arn,
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        var.sns_topic_arn,
      ]
    }
  }
}

# Sets the default SQS policy on the queue to allow the SNS topic to publish messages to the queue.
#
# Note, this currently overrides any existing SQS policy, so this only works with a single publisher, and only works if consumers access
# the queue via IAM policy.
resource "aws_sqs_queue_policy" "default" {
  queue_url = var.sqs_queue_url
  policy    = data.aws_iam_policy_document.default.json
}
