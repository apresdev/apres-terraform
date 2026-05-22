locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = var.component
      "owner"       = var.owner
      "environment" = var.environment
      "managed-by"  = "Terraform"
      "severity"    = var.severity
      "runbook"     = var.runbook
      "source"      = "apres_cloudwatch_alarm_module"
    })
  )

  alarm_name  = "${module.apres_names.local_name}-${var.severity}"
  description = "${var.description}\n***\nRunbook: ${var.runbook}"
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}

resource "aws_cloudwatch_metric_alarm" "standard_alarm" {

  # common fields shared between both styles
  alarm_name          = local.alarm_name
  alarm_description   = local.description
  evaluation_periods  = var.evaluation_periods
  comparison_operator = var.comparison_operator
  treat_missing_data  = var.treat_missing_data

  tags = merge(
    local.tags,
    {
      Name = local.alarm_name
    },
  )

  # Standard Metric Alarm fields
  metric_name = var.metric_name
  namespace   = var.namespace
  period      = var.period
  statistic   = var.statistic
  threshold   = var.threshold
  dimensions  = var.dimensions
}
