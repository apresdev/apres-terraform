# The resources are aws_cloudwatch_event_*, because EventBridge was formerly called CloudWatch Events. Functionality is identical.

resource "aws_cloudwatch_event_rule" "security_hub" {
  name        = "SecurityHubCriticalHighFindings"
  description = "Security Hub critical and high severity findings"
  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail" : {
      "findings" : {
        "Severity" : {
          //filter only High and Critical serverity findings
          "Label" : ["HIGH", "CRITICAL"]
        },
        "Workflow" : {
          //only push "NEW" findings, if the findings status is "NOTIFIED" it won't be pushed.
          "Status" : ["NEW"]
        }
      }
    }
  })
  tags = merge(
    local.tags,
    {
      Name = "SecurityHubCriticalHighFindings"
    },
  )
}

resource "aws_cloudwatch_event_target" "security_hub" {
  rule      = aws_cloudwatch_event_rule.security_hub.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_hub.arn
}

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

