# The resources are aws_cloudwatch_event_*, because EventBridge was formerly called CloudWatch Events. Functionality is identical.

resource "aws_cloudwatch_event_rule" "security_hub" {
  name        = "SecurityHubCriticalHighFindings"
  description = "Security Hub critical and high severity findings"
  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail" : {
      "findings" : {
        "Severity" : {
          //filter only High and Critical severity findings
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
  role_arn  = aws_iam_role.eventbridge_sns_topic.arn
}

data "aws_iam_policy_document" "eventbridge_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_sns_topic_policy" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.security_hub.arn]
  }
}

resource "aws_iam_role" "eventbridge_sns_topic" {
  name               = "eventbridge-sns-topic-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role_policy.json
  inline_policy {
    name   = "eventbridge-sns-topic-policy"
    policy = data.aws_iam_policy_document.eventbridge_sns_topic_policy.json
  }
}
