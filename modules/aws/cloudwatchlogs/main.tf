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
  kms_alias_arn = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.cwl_kms_alias_name}"
}

resource "aws_cloudwatch_log_group" "default" {
  #checkov:skip=CKV_AWS_158:False positive, KMS key is defined and required.connection
  #checkov:skip=CKV_AWS_338:Logs should be kept for a year except this doesn't make sense in dev/test environments.
  name              = var.path
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_alias_arn
  tags = merge(
    local.tags,
    {
      Name = "${title(var.name)} ${var.environment} CloudWatch Logs"
    },
  )
}