# We can use the IAM Policy Document for the Key Policy
data "aws_iam_policy_document" "kms" {
  #checkov:skip=CKV_AWS_356:Resources need to be '*' for this policy.
  #checkov:skip=CKV_AWS_111:Write must be unconstrained for this policy.
  #checkov:skip=CKV_AWS_109:Policy cannot have constraints.
  statement {
    sid       = "Allow account to use the key"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid    = "Allow SNS to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
  dynamic "statement" {
    for_each = var.publishing_services
    content {
      sid    = "Allow${title(split(".", statement.value)[0])}ToUseKMS"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = [statement.value]
      }
    }
  }
}

resource "aws_kms_key_policy" "default" {
  key_id = aws_kms_key.default.id
  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_key" "default" {
  description             = "${title(var.name)} Alerting SNS Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(
    local.tags,
    {
      Name = "${title(var.name)} Alerting SNS Key"
    },
  )
}

resource "aws_kms_alias" "default" {
  name          = local.sns_key_alias
  target_key_id = aws_kms_key.default.id
}