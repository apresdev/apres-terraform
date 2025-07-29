module "s3" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  mfa_delete  = false # Need this to be false or we can't delete it.
  owner       = "Testing"
  application = "UnitTests"
  component   = "S3"
  region      = data.aws_region.current.id
  account_id  = data.aws_caller_identity.current.account_id
  lifecycle_rule = {
    enabled = true
  }
  cors_rules = [
    {
      allowed_methods = ["PUT"]
      allowed_origins = ["localhost"]
    }
  ]
  replication_source_config = {
    enabled                              = var.test_replication
    destination_account_id               = data.aws_caller_identity.current.account_id
    destination_bucket_arn               = var.test_replication ? module.s3_destination[0].bucket_arn : null
    destination_encryption_sse_algorithm = "SSE-KMS"
    destination_kms_key_arn              = var.test_replication ? aws_kms_key.destination[0].arn : null
    destination_region                   = data.aws_region.current.name
    owner_translation                    = true
    replication_prefix                   = ""
    replicate_delete_markers             = true
  }
}

resource "aws_kms_key" "destination" {
  count                   = var.test_replication ? 1 : 0
  description             = "${var.environment} KMS key for S3 bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

module "s3_destination" {
  count                    = var.test_replication ? 1 : 0
  source                   = "../../"
  name                     = "${var.name}dest"
  environment              = var.environment
  mfa_delete               = false # Need this to be false or we can't delete it.
  owner                    = "Testing"
  application              = "UnitTests"
  component                = "S3"
  region                   = data.aws_region.current.id
  account_id               = data.aws_caller_identity.current.account_id
  encryption_sse_algorithm = "SSE-KMS"
  encryption_kms_key_arn   = aws_kms_key.destination[0].arn
  lifecycle_rule = {
    enabled = true
  }
  versioning = true
  replication_destination_config = {
    enabled                        = true
    source_bucket_in_other_account = false # it's in the same account
    source_bucket_arn              = lower("arn:aws:s3:::${data.aws_caller_identity.current.account_id}-${var.environment}-${data.aws_region.current.name}-${var.name}")
    source_service_role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.environment}-${var.name}-${data.aws_region.current.name}-ReplicationSource"
  }
}