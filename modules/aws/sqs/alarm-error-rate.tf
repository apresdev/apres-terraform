resource "aws_cloudwatch_metric_alarm" "error_rate" {
  count = length(var.error_rate_alarms)

  alarm_name          = "${local.queue_name}-error-rate-${count.index + 1}-sev${var.error_rate_alarms[count.index].severity}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = var.error_rate_alarms[count.index].datapoints_to_alarm
  evaluation_periods  = var.error_rate_alarms[count.index].evaluation_periods
  threshold           = var.error_rate_alarms[count.index].threshold
  alarm_description   = <<EOF
  Error rate exceeds ${var.error_rate_alarms[count.index].threshold} percent for ${var.error_rate_alarms[count.index].evaluation_periods} x ${var.error_rate_alarms[count.index].period} seconds
  EOF

  metric_query {
    id          = "error_rate"
    expression  = "IF( total > 0, ( failed / total ) * 100, 0 )"
    label       = "Error Rate"
    return_data = true
  }

  metric_query {
    id         = "total"
    expression = "IF( failed, failed, 0) + IF( success, success, 0)"
    label      = "Error Rate"
  }

  metric_query {
    id = "success"

    metric {
      metric_name = "NumberOfMessagesSent"
      namespace   = "AWS/SQS"
      period      = var.error_rate_alarms[count.index].period
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.default.name
      }
    }
  }

  metric_query {
    id = "failed"

    metric {
      metric_name = "NumberOfMessagesSent"
      namespace   = "AWS/SQS"
      period      = var.error_rate_alarms[count.index].period
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.deadletter.name
      }
    }
  }

  tags = merge(
    local.tags,
    tomap({
      Name = "${local.queue_name}-error-rate-sev${var.error_rate_alarms[count.index].severity}"
    })
  )
}
