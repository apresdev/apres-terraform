locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = var.component
      "owner"       = var.owner
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )

  use_vpc       = var.vpc != null && var.vpc.enabled == true
  region        = data.aws_region.current.name
  account_id    = data.aws_caller_identity.current.account_id
  name          = "${lower(var.environment)}-${lower(var.name)}"
  regional_name = "${local.account_id}-${lower(var.lambda_regional_environment)}-${local.region}-lambda-artifacts"

  archive_path = "${path.module}/.build/${local.name}.zip"

  log_group = "/apres/lambda/${local.name}"


}
