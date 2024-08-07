resource "aws_cloudwatch_metric_alarm" "projected_latency" {
  count = length(var.projected_latency_alarms)

  alarm_name          = "${local.queue_name}-projected-latency-${count.index + 1}-sev${var.projected_latency_alarms[count.index].severity}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = var.projected_latency_alarms[count.index].datapoints_to_alarm
  evaluation_periods  = var.projected_latency_alarms[count.index].evaluation_periods
  threshold           = 1
  alarm_description   = <<EOF
  Expected forward latency exceeds ${var.projected_latency_alarms[count.index].threshold} seconds for ${var.projected_latency_alarms[count.index].evaluation_periods} x ${var.projected_latency_alarms[count.index].period} seconds
  EOF

  # This is a bit confusing, so I will do my best to explain.
  # There are three scenarios we want to account for:
  #   1) there is nothing in the queue (no alarm)
  #   2) there is something in the queue and there are no active consumers (alarm)
  #   3) there is something in the queue, there are active consumers, but the consumers are too slow to satisfy the SLO (alarm)
  #
  # So the first IF checks the total count, if its 0 then we are in scenario #1.  
  # Otherwise, we check the delete rate, if it is 0 then we are in scenario #2
  # Finally, we calculate the expected latency (total / delete_rate) and set the alarm state if and only if it is greater than the 
  # threshold.
  #
  # This is the best way to handle this as there technically the expected latency is infinity if the delete_rate is zero but the total is 
  # non-zero.  So instead of using the threshold as the threshold for the alarm, we pass it in the IF statement and simple treat the metric
  # as binary, either in alarm or not in alarm state.
  metric_query {
    id          = "alarm"
    expression  = "IF( queue_depth == 0, 0, IF( departure_rate == 0, 1, IF( projected_latency > ${var.projected_latency_alarms[count.index].threshold}, 1, 0) ) )"
    label       = "Alarm State"
    return_data = true
  }

  # This calculates the expected amount of time a message will remain in the queue if it is added to the queue right now, provided nothing else changes.
  # The time in queue calculated using a variation of Little's Law, W = L / lambda, where W is the time spent in the queue, L is the total 
  # queue depth, and lambda is the departure rate (instead of the arrival rate).
  metric_query {
    id          = "projected_latency"
    expression  = "IF( queue_depth > 0 && departure_rate > 0 , queue_depth / departure_rate )"
    label       = "Projected Latency"
    return_data = false
  }

  # This calculates the rate at which items are currently being removed from the queue.
  metric_query {
    id          = "departure_rate"
    expression  = "IF( deleted, deleted / PERIOD(deleted), 0 )"
    label       = "Departure Rate"
    return_data = false
  }

  # This calculates the total number of messages in the queue.
  metric_query {
    id          = "queue_depth"
    expression  = "IF( visible, visible, 0 ) + IF( not_visible, not_visible, 0 ) + IF( delayed, delayed, 0 )"
    label       = "Queue Depth"
    return_data = false
  }

  # This counts the total number of visible messages in the queue.
  metric_query {
    id = "visible"

    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      period      = var.projected_latency_alarms[count.index].period
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.default.name
      }
    }
  }

  # This counts the total number of non-visible (in process) messages in the queue.
  metric_query {
    id = "not_visible"

    metric {
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      namespace   = "AWS/SQS"
      period      = var.projected_latency_alarms[count.index].period
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.default.name
      }
    }
  }

  # This counts the total number of delayed (about to be added) messages in the queue.
  metric_query {
    id = "delayed"

    metric {
      metric_name = "ApproximateNumberOfMessagesDelayed"
      namespace   = "AWS/SQS"
      period      = var.projected_latency_alarms[count.index].period
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.default.name
      }
    }
  }

  # This calculates the total number of messages that have been removed from the queue recently. 
  metric_query {
    id = "deleted"

    metric {
      metric_name = "NumberOfMessagesDeleted"
      namespace   = "AWS/SQS"
      period      = var.projected_latency_alarms[count.index].period
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = aws_sqs_queue.default.name
      }
    }
  }

  tags = merge(
    local.tags,
    tomap({
      Name = "${local.queue_name}-projected-latency-sev${var.projected_latency_alarms[count.index].severity}"
    })
  )
}
