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
  queue_name = "${data.aws_caller_identity.current.account_id}-${lower(var.environment)}-${data.aws_region.current.name}-${lower(var.name)}"
}