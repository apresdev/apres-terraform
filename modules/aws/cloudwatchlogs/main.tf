locals {
  tags = merge(
    var.default_tags,
    tomap({ "environment" = var.environment, "component" = var.name, "application" = var.name }),
  )
}

resource "aws_cloudwatch_log_group" "default" {
  #checkov:skip=CKV_AWS_158:False positive, KMS key is defined and required.connection
  #checkov:skip=CKV_AWS_338:Logs should be kept for a year except this doesn't make sense in dev/test environments.
  name              = var.path
  retention_in_days = var.retention_in_days
  kms_key_id        = length(var.kms_key_arn) == 0 ? aws_kms_key.cwl[0].arn : var.kms_key_arn
  tags = merge(
    local.tags,
    {
      Name = "${var.name} CloudWatch Logs"
    },
  )
}