module "alarm" {
  source              = "../../"
  name                = var.name
  description         = var.description
  application         = "UnitTest"
  component           = "UnitTest"
  environment         = var.environment
  severity            = var.severity
  runbook             = var.runbook
  evaluation_periods  = var.evaluation_periods
  comparison_operator = var.comparison_operator
  treat_missing_data  = "breaching" # need this for alarms that don't actually do anything
  namespace           = var.namespace
  metric_name         = var.metric_name
  dimensions          = var.dimensions
  period              = var.period
  threshold           = var.threshold
  statistic           = var.statistic
}