locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application,
      "component"   = "CostManagement"
      "owner"       = var.owner,
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )
}