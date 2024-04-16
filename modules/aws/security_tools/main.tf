locals {
  tags = merge(
    var.default_tags,
    tomap({ "environment" = var.environment })
  )
  securityhub_sns_key_alias = "alias/apres/securityhub-sns"
}