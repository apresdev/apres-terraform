# The following best practices are applied to the table by default:
#
# CKV_AWS_26 : Ensure all data stored in the SNS topic is encrypted
# CKV_AWS_169: Ensure SNS topic policy is not public by only allowing specific services or principals to access it
#
# The following are applied if configured:
#
resource "aws_sns_topic" "default" {
  name         = local.topic_name
  display_name = coalesce(var.display_name, local.topic_name)

  #CKV_AWS_169: Ensure SNS topic policy is not public by only allowing specific services or principals to access it
  policy = coalesce(var.policy, data.aws_iam_policy_document.sns-topic-policy.json)

  #CKV_AWS_26 : Ensure all data stored in the SNS topic is encrypted
  kms_master_key_id = var.encryption_kms_key_id

  tags = merge(
    local.tags,
    tomap({
      Name = local.topic_name
    })
  )

  depends_on = [data.aws_caller_identity.current]

}

