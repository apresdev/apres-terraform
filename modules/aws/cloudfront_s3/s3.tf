
# Module for the S3 bucket
module "s3" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/4.1.0"
  name        = lower(var.name)
  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = "S3"
  versioning  = true
  mfa_delete  = false
  # Disable default policy, we'll add our own and include the default.
  set_default_bucket_policy = false
  encryption_sse_algorithm  = "SSE-KMS"
  encryption_kms_key_arn    = aws_kms_key.default.arn
  lifecycle_rule = {
    enabled                  = true
    old_versions_delete_days = 90
  }
  cors_rules = var.allow_browser_uploads ? [{
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
  }] : []
  replication_destination_config = {
    enabled                 = var.replication_destination_config.enabled
    source_bucket_account   = var.replication_destination_config.source_bucket_account
    source_bucket_arn       = var.replication_destination_config.source_bucket_arn
    source_service_role_arn = var.replication_destination_config.source_service_role_arn
  }
  replication_source_config = {
    enabled                              = var.replication_source_config.enabled
    destination_account_id               = var.replication_source_config.destination_account_id
    destination_bucket_arn               = var.replication_source_config.destination_bucket_arn
    destination_encryption_sse_algorithm = "SSE-KMS"
    destination_kms_key_arn              = var.replication_source_config.destination_kms_key_arn
    destination_region                   = var.replication_source_config.destination_region
    owner_translation                    = var.replication_source_config.owner_translation
    replicate_delete_markers             = var.replication_source_config.replicate_delete_markers
    replication_prefix                   = var.replication_source_config.replication_prefix
  }
}

# Bucket policy to allow CloudFront to write to the logs bucket
data "aws_iam_policy_document" "cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${module.s3.bucket_arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.default.arn]
    }
  }
  # add the default policy and replication policy if enabled
  source_policy_documents = var.replication_destination_config.enabled ? [module.s3.replication_bucket_policy] : [module.s3.default_bucket_policy]
}

resource "aws_s3_bucket_policy" "s3" {
  bucket     = module.s3.bucket_name
  policy     = data.aws_iam_policy_document.cloudfront.json
  depends_on = [module.s3, aws_cloudfront_distribution.default]
}

# Logs bucket for CF
module "s3_logs" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/4.1.0"
  name        = "${lower(var.name)}-logs"
  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = "S3Logs"
  versioning  = true
  mfa_delete  = false
  lifecycle_rule = {
    enabled = false # setting a separate policy below
  }
  encryption_sse_algorithm = "SSE-KMS"
  encryption_kms_key_arn   = aws_kms_key.logging.arn
}

# Add the ACL's required for CloudFront to be able to log
resource "aws_s3_bucket_acl" "logging" {
  bucket     = module.s3_logs.bucket_name
  depends_on = [module.s3_logs, aws_s3_bucket_ownership_controls.logging]

  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    grant {
      grantee {
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "logging" {
  #checkov:skip=CKV2_AWS_65:Correct check, but the ownership controls are required to allow CloudFront to write to the bucket.
  depends_on = [module.s3_logs]
  bucket     = module.s3_logs.bucket_name

  rule {
    object_ownership = "ObjectWriter"
  }
}

# Lifecycle for logs in the logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  bucket     = module.s3_logs.bucket_name
  depends_on = [module.s3_logs]

  rule {
    id     = "s3-cloudfront-${lower(var.name)}-logs-transitions"
    status = "Enabled"

    transition {
      days          = var.cloudfront_logs_transition_ia
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.cloudfront_logs_transition_glacier
      storage_class = "GLACIER"
    }

    expiration {
      days = var.cloudfront_logs_expiration
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
