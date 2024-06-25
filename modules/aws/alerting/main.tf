locals {
  sns_key_alias = "alias/apres/alerting-sns"
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application,
      "component"   = var.component,
      "owner"       = var.owner,
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )
}