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
  account_id      = data.aws_caller_identity.current.account_id
  name            = module.apres_names.local_name
  # Need a region for the workload bucket, so either use the one passed in as destination or the current one.
  region          = var.region == "" ? data.aws_region.current.region : var.region
  artifact_bucket = "${local.account_id}-${lower(var.lambda_regional_environment)}-${local.region}-lambda-artifacts"
  artifact_key    = "unsigned/${local.name}.zip"

  archive_path = "${path.module}/.build/${local.name}.zip"

  log_group = "/apres/lambda/${local.name}"

  # The actual artifact to upload for code signing
  artifact      = var.source_file == "" ? var.zip_file : data.archive_file.lambda[0].output_path
  artifact_hash = var.source_file == "" ? var.zip_file_hash : data.archive_file.lambda[0].output_md5
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.0"
  name        = var.name
  environment = var.environment
}