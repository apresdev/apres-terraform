resource "aws_ce_anomaly_monitor" "default" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  tags = merge(
    local.tags,
    {
      Name = "AWSServiceMonitor",
    },
  )
}

resource "aws_ce_anomaly_subscription" "chat" {
  count = local.enable_chat_alerts ? 1 : 0
  name  = "AWSServiceMonitorAlertSubscriptionChat"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.default.arn
  ]

  dynamic "subscriber" {
    for_each = module.alerting[0].sns_topic_arns
    content {
      type    = "SNS"
      address = subscriber.value
    }
  }

  frequency = var.frequency

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
        match_options = ["GREATER_THAN_OR_EQUAL"]
        values        = [tostring(var.anomaly_alert_on_percentage)]
      }
    }
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        match_options = ["GREATER_THAN_OR_EQUAL"]
        values        = [tostring(var.anomaly_alert_on_dollars)]

      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "CostMonitorSubscriptionChat",
    },
  )
}

locals {
  # See note on var.frequency
  frequency = var.frequency == "IMMEDIATE" ? "DAILY" : var.frequency
}

resource "aws_ce_anomaly_subscription" "email" {
  count = length(var.email_addresses) > 0 ? 1 : 0
  name  = "AWSServiceMonitorAlertSubscriptionEmail"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.default.arn
  ]

  dynamic "subscriber" {
    for_each = var.email_addresses
    content {
      type    = "EMAIL"
      address = subscriber.value
    }
  }

  frequency = local.frequency

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
        match_options = ["GREATER_THAN_OR_EQUAL"]
        values        = [tostring(var.anomaly_alert_on_percentage)]
      }
    }
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        match_options = ["GREATER_THAN_OR_EQUAL"]
        values        = [tostring(var.anomaly_alert_on_dollars)]

      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "CostMonitorSubscriptionEmail",
    },
  )
}