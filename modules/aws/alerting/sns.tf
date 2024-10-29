resource "aws_sns_topic" "default" {
  depends_on   = [aws_kms_alias.default]
  display_name = "${module.apres_names.local_name} Apres Alerting"
  # Topic name, different from the naming standard.
  name              = "apres-alerting-${lower(var.name)}-${lower(var.environment)}"
  kms_master_key_id = local.sns_key_alias
  tags = merge(
    local.tags,
    {
      Name = "apres-alerting-${lower(var.name)}-${lower(var.environment)}"
    },
  )
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.default.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  dynamic "statement" {
    for_each = var.publishing_services
    content {
      sid     = "Allow${title(split(".", statement.value)[0])}Publish"
      effect  = "Allow"
      actions = ["sns:Publish"]
      principals {
        type        = "Service"
        identifiers = [statement.value]
      }

      resources = [aws_sns_topic.default.arn]
    }
  }
}

resource "aws_sns_topic_subscription" "default" {
  # Create one subscription per email address
  count     = length(var.email_addresses)
  topic_arn = aws_sns_topic.default.arn
  protocol  = "email"
  endpoint  = var.email_addresses[count.index]
}