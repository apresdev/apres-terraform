data "aws_iam_policy_document" "replication_destination" {
  count = var.replication_destination_config.enabled ? 1 : 0
  statement {
    sid    = "Allow replication from ${var.replication_destination_config.source_bucket_account}"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.replication_destination_config.source_bucket_account}:root"]
    }
  }
}

data "aws_iam_policy_document" "default_kms_key" {
  #checkov:skip=CKV_AWS_356: KMS key needs a * for the resource.
  #checkov:skip=CKV_AWS_111: Not applicable for key policy.
  #checkov:skip=CKV_AWS_109: Not applicable for key policy.
  statement {
    sid    = "Allow account to use the key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "Allow CloudFront to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.default.arn]
    }
  }
  # add the kms policy to allow replication if enabled.
  source_policy_documents = var.replication_destination_config.enabled ? [data.aws_iam_policy_document.replication_destination[0].json] : []
}

resource "aws_kms_key_policy" "default" {
  key_id = aws_kms_key.default.id
  policy = data.aws_iam_policy_document.default_kms_key.json
}

resource "aws_kms_key" "default" {
  description             = "${local.name} CloudFront S3 Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(
    local.tags,
    {
      Name = "${local.name} CloudFront S3 Key"
    },
  )
}

resource "aws_kms_alias" "default" {
  name          = "alias/apres/${local.name}-cloudfront_s3"
  target_key_id = aws_kms_key.default.id
}

resource "aws_kms_key" "logging" {
  description             = "${local.name} CloudFront S3 Logging Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(
    local.tags,
    {
      Name = "${local.name} CloudFront S3 Logging Key"
    },
  )
}

resource "aws_kms_alias" "logging" {
  name          = "alias/apres/${local.name}-cloudfront_s3-logging"
  target_key_id = aws_kms_key.logging.id
}

data "aws_iam_policy_document" "logging_kms_key" {
  #checkov:skip=CKV_AWS_356: KMS key needs a * for the resource.
  #checkov:skip=CKV_AWS_111: Not applicable for key policy.
  #checkov:skip=CKV_AWS_109: Not applicable for key policy.
  statement {
    sid    = "Allow account to use the key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "Allow CloudFront Log Delivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.default.arn]
    }
  }
}

resource "aws_kms_key_policy" "logging" {
  key_id = aws_kms_key.logging.id
  policy = data.aws_iam_policy_document.logging_kms_key.json
}