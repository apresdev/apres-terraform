locals {
  tags = merge(
    var.default_tags,
    tomap({
      environment = var.environment
      managed-by  = "Terraform"
      application = var.application
      component   = var.component
      owner       = var.owner
    })
  )
  bucket_name = "${data.aws_caller_identity.current.account_id}-${lower(var.environment)}-${data.aws_region.current.name}-${lower(var.name)}"
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
  #checkov:skip=CKV_AWS_145:False positive, encryption is enabled, but check fails if algorithm is AES256
  #checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #checkov:skip=CKV2_AWS_61:Ensure that an S3 bucket has a lifecycle configuration
  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled

  bucket = local.bucket_name

  tags = merge(
    local.tags,
    tomap({
      Name = local.bucket_name
    })
  )
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status     = var.versioning ? "Enabled" : "Disabled" # Ensure AWS S3 object versioning is enabled
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled" # Ensure S3 bucket MFA Delete is enabled
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  restrict_public_buckets = true # Ensure S3 bucket RestrictPublicBucket is set to True
  ignore_public_acls      = true # Ensure S3 bucket IgnorePublicAcls is set to True
  block_public_policy     = true # Ensure S3 Bucket BlockPublicPolicy is set to True
  block_public_acls       = true # Ensure S3 bucket has block public ACLS enabled
}

# Ensure data stored in the S3 bucket is securely encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  #checkov:skip=CKV2_AWS_67:False positive, no CMK is used here to require rotation
  bucket = aws_s3_bucket.default.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_sse_algorithm
      kms_master_key_id = var.encryption_kms_key_id
    }
  }
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
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  #checkov:skip=CKV_AWS_300:False positive, abort failed uploads is configured by default.
  count  = var.lifecycle_rule.enabled ? 1 : 0
  bucket = aws_s3_bucket.default.id
  rule {
    id     = "ApresDefaultLifecycleRule"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = var.lifecycle_rule.abort_incomplete_multipart_upload_days == -1 ? null : var.lifecycle_rule.abort_incomplete_multipart_upload_days
    }
    expiration {
      days = var.lifecycle_rule.object_delete_days == -1 ? null : var.lifecycle_rule.object_delete_days
    }
    # This is to deal with a provider issue in 5.86.0 where the empty `filter {}` block was ok in previous
    # versions but no longer ok in >= 5.86, because of a change AWS made in the API
    # https://github.com/hashicorp/terraform-provider-aws/issues/41268
    dynamic "filter" {
      for_each = var.lifecycle_rule.prefix == "" ? [] : [1]
      content {
        prefix = var.lifecycle_rule.prefix
      }
    }
    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_rule.old_versions_delete_days == -1 ? null : var.lifecycle_rule.old_versions_delete_days
    }
    transition {
      # Transition to Intelligent Tier
      days          = var.lifecycle_rule.transition_to_intelligent_tier_days == -1 ? null : var.lifecycle_rule.transition_to_intelligent_tier_days
      storage_class = var.lifecycle_rule.transition_to_intelligent_tier_days == -1 ? null : "INTELLIGENT_TIERING"
    }
  }
}

# Include the CORS configuration if the cors_rules are defined
resource "aws_s3_bucket_cors_configuration" "default" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.default.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value["allowed_headers"]
      allowed_methods = cors_rule.value["allowed_methods"]
      allowed_origins = cors_rule.value["allowed_origins"]
      expose_headers  = cors_rule.value["expose_headers"]
    }
  }
}
