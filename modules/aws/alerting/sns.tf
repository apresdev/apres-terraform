# Create the SNS resources. These are created in every region where this
# stack is deployed.
resource "aws_sns_topic" "default" {
  depends_on   = [aws_kms_alias.default]
  for_each     = toset(local.all_sns_topic_names)
  display_name = "${title(each.value)} Alerting"
  # Topic name, different from the naming standard.
  name              = each.value
  kms_master_key_id = local.sns_key_alias
  tags = merge(
    local.tags,
    {
      Name = "apres-alerting-${lower(each.value)}"
    },
  )
}

resource "aws_sns_topic_policy" "default" {
  for_each = toset(local.all_sns_topic_names)
  arn      = aws_sns_topic.default[each.value].arn
  policy   = data.aws_iam_policy_document.sns_topic_policy[each.value].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  for_each = toset(local.all_sns_topic_names)
  dynamic "statement" {
    for_each = local.all_publishing_services
    content {
      sid     = "Allow${title(split(".", statement.value)[0])}Publish"
      effect  = "Allow"
      actions = ["sns:Publish"]
      principals {
        type        = "Service"
        identifiers = [statement.value]
      }

      resources = [aws_sns_topic.default[each.value].arn]
    }
  }
}
