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
}