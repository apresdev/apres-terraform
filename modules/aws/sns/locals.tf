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

  topic_name = "${local.account_id}-${lower(var.environment)}-${local.region}-${lower(var.name)}"
  topic_arn  = "arn:aws:sns:${local.region}:${local.account_id}:${local.topic_name}"
}