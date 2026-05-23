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
  count     = local.alerting_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.security_hub.name
  target_id = "SendToSNS"
  arn       = module.alerting[0].sns_topic_arns[0]
}
