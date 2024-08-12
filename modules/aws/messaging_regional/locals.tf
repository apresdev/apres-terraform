locals {
  tags = merge(
    var.default_tags,
    tomap({
      environment = var.environment
      managed-by  = "Terraform"
      application = var.application
      component   = var.component
      owner       = var.owner
    })
  )
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}
