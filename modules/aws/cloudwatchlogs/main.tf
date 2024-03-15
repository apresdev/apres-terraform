locals {
  tags = merge(
    var.default_tags,
    tomap({ "environment" = var.environment, "component" = var.name, "application" = var.name }),
  )
}

resource "aws_cloudwatch_log_group" "default" {
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