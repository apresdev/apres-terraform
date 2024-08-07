resource "aws_cloudwatch_metric_alarm" "historical_latency" {
  count = length(var.historical_latency_alarms)

  alarm_name          = "${local.queue_name}-historical-latency-${count.index + 1}-sev${var.historical_latency_alarms[count.index].severity}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = var.historical_latency_alarms[count.index].datapoints_to_alarm
  evaluation_periods  = var.historical_latency_alarms[count.index].evaluation_periods
  threshold           = var.historical_latency_alarms[count.index].threshold
  period              = var.historical_latency_alarms[count.index].period
  alarm_description   = "Actual latency exceeds ${var.historical_latency_alarms[count.index].threshold} seconds for ${var.historical_latency_alarms[count.index].evaluation_periods} x ${var.historical_latency_alarms[count.index].period} seconds"

  metric_name = "ApproximateAgeOfOldestMessage"
  namespace   = "AWS/SQS"
  statistic   = "Maximum"
  unit        = "Seconds"

  dimensions = {
    QueueName = aws_sqs_queue.default.name
  }

  tags = merge(
    local.tags,
    tomap({
      Name = "${local.queue_name}-historical-latency-sev${var.historical_latency_alarms[count.index].severity}"
    })
  )
}
