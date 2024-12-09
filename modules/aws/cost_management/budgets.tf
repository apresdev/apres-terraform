resource "aws_budgets_budget" "default" {
  name         = var.budget_name
  budget_type  = "COST"
  limit_unit   = "USD"
  limit_amount = var.budget_limit
  time_unit    = "MONTHLY"

  # Setup budget notifications. Loop through the thresholds above and create one per item
  dynamic "notification" {
    for_each = var.budget_alert_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value["percent"]
      threshold_type             = "PERCENTAGE"
      notification_type          = notification.value["type"]
      subscriber_email_addresses = var.email_addresses
      subscriber_sns_topic_arns  = local.enable_chat_alerts ? module.alerting[0].sns_topic_arns : []
    }
  }
}