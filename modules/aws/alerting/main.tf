locals {
  sns_key_alias = "alias/apres/alerting-sns"
  tags = merge(
    var.default_tags,
    tomap({ "environment" = var.environment })
  )
}