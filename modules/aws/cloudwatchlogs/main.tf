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
  kms_alias_arn = "arn:aws:kms:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.cwl_kms_alias_name}"
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.0"
  name        = var.name
  environment = var.environment
}

resource "aws_cloudwatch_log_group" "default" {
  #checkov:skip=CKV_AWS_158:False positive, KMS key is defined and required.connection
  #checkov:skip=CKV_AWS_338:Logs should be kept for a year except this doesn't make sense in dev/test environments.
  name              = var.path
  region            = var.region
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_alias_arn
  tags = merge(
    local.tags,
    {
      Name = module.apres_names.local_name
    },
  )
}