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

  use_vpc         = var.vpc != null && var.vpc.enabled == true
  region          = data.aws_region.current.name
  account_id      = data.aws_caller_identity.current.account_id
  name            = module.apres_names.local_name
  artifact_bucket = "${local.account_id}-${lower(var.lambda_regional_environment)}-${local.region}-lambda-artifacts"

  archive_path = "${path.module}/.build/${local.name}.zip"

  log_group = "/apres/lambda/${local.name}"

  # The actual artifact to upload for code signing
  artifact = var.skip_zip ? var.binary_path : data.archive_file.lambda[0].output_path
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/1.0.0"
  name        = var.name
  environment = var.environment
}