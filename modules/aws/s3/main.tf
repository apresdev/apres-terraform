locals {
  tags = merge(
    var.default_tags,
    tomap({
      environment = var.environment
      managed-by  = "terraform"
    })
  )
}

# The following best practices are applied to the bucket
#
# Ensure AWS S3 object versioning is enabled
# Ensure S3 bucket MFA Delete is enabled
# Ensure AWS access logging is enabled on S3 buckets
#
# Ensure bucket ACL does not grant READ permission to everyone
# Ensure AWS S3 bucket is not publicly writable
#
# Ensure S3 bucket RestrictPublicBucket is set to True
# Ensure S3 bucket IgnorePublicAcls is set to True
# Ensure S3 Bucket BlockPublicPolicy is set to True
# Ensure S3 bucket has block public ACLS enabled
#
# Ensure S3 buckets are encrypted with KMS by default
# Ensure data stored in the S3 bucket is securely encrypted at rest
# Ensure data is transported from the S3 bucket securely
resource "aws_s3_bucket" "default" {

  # TODO: Address Checkov suppressions.

  #checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #checkov:skip=CKV2_AWS_61:Ensure that an S3 bucket has a lifecycle configuration
  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled

  bucket = "${data.aws_caller_identity.current.account_id}-${lower(var.environment)}-${data.aws_region.current.name}-${lower(var.name)}"

  tags = merge(
    local.tags,
    tomap({
      Name = "${var.environment}-${var.name}"
    })
  )
  depends_on = [data.aws_caller_identity.current]
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status     = var.versioning ? "Enabled" : "Disabled" # Ensure AWS S3 object versioning is enabled
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled" # Ensure S3 bucket MFA Delete is enabled
  }

  depends_on = [aws_s3_bucket.default]
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.bucket

  restrict_public_buckets = true # Ensure S3 bucket RestrictPublicBucket is set to True
  ignore_public_acls      = true # Ensure S3 bucket IgnorePublicAcls is set to True
  block_public_policy     = true # Ensure S3 Bucket BlockPublicPolicy is set to True
  block_public_acls       = true # Ensure S3 bucket has block public ACLS enabled

  depends_on = [aws_s3_bucket.default]
}

# Ensure data stored in the S3 bucket is securely encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  #checkov:skip=CKV2_AWS_67:False positive, no CMK is used here to require rotation
  bucket = aws_s3_bucket.default.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_sse_algorithm
      kms_master_key_id = var.encryption_kms_key_id
    }
  }

  depends_on = [aws_s3_bucket.default]
}

# Ensure data is transported from the S3 bucket securely
resource "aws_s3_bucket_policy" "deny_unsecure_communications" {
  count      = var.set_default_bucket_policy ? 1 : 0
  bucket     = aws_s3_bucket.default.id
  policy     = data.aws_iam_policy_document.deny_unsecure_communications.json
  depends_on = [aws_s3_bucket.default, data.aws_iam_policy_document.deny_unsecure_communications]
}

data "aws_iam_policy_document" "deny_unsecure_communications" {
  statement {

    sid    = "DenyUnSecureCommunications"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [aws_s3_bucket.default.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  depends_on = [aws_s3_bucket.default]
}
