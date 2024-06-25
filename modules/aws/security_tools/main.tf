locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application,
      "component"   = "SecurityTools"
      "owner"       = var.owner,
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )
  securityhub_sns_key_alias = "alias/apres/securityhub-sns"
}