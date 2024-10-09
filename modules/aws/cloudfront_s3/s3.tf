# Module for the S3 bucket
module "s3" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.1"
  name        = lower(var.name)
  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = "S3"
  versioning  = true
  mfa_delete  = false
  # Disable default policy, we'll add our own and include the default.
  set_default_bucket_policy = false
  encryption_sse_algorithm  = "aws:kms"
  encryption_kms_key_id     = aws_kms_key.default.arn
  lifecycle_rule = {
    enabled                  = true
    old_versions_delete_days = 90
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
  # add the default policy
  source_policy_documents = [module.s3.default_bucket_policy]
}

resource "aws_s3_bucket_policy" "s3" {
  bucket     = module.s3.bucket_name
  policy     = data.aws_iam_policy_document.cloudfront.json
  depends_on = [module.s3, aws_cloudfront_distribution.default]
}

# Logs bucket for CF
module "s3_logs" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/2.0.1"
  name        = "${lower(var.name)}-logs"
  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = "S3Logs"
  versioning  = true
  mfa_delete  = false # TODO enable this later, see race condition.
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
