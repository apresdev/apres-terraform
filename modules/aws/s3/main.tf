#
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

  bucket = "${data.aws_caller_identity.current.account_id}-${var.environment}-${data.aws_region.current.name}-${var.name}"

  tags = {
    Name = "${var.environment}-${var.name}"
  }

  depends_on = [data.aws_caller_identity.current]

}

# TODO: Figure out where access logging should go...
# # Ensure AWS access logging is enabled on S3 buckets
# resource "aws_s3_bucket_logging" "example" {
#   bucket = aws_s3_bucket.default.id

#   target_bucket = aws_s3_bucket.default.id
#   target_prefix = "log/"

#   depends_on = [aws_s3_bucket.default]
# }

resource "aws_s3_bucket_acl" "default" {

  bucket = aws_s3_bucket.default.id

  # Ensure bucket ACL does not grant READ permission to everyone
  # Ensure AWS S3 bucket is not publicly writable
  acl = "private"

  depends_on = [aws_s3_bucket.default]

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

  bucket = aws_s3_bucket.default.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms" # Ensure S3 buckets are encrypted with KMS by default
    }
  }

  depends_on = [aws_s3_bucket.default]

}

# Ensure data is transported from the S3 bucket securely
resource "aws_s3_bucket_policy" "deny_unsecure_communications" {

  bucket = aws_s3_bucket.default.id

  policy = data.aws_iam_policy_document.deny_unsecure_communications.json

  # policy = jsonencode([{
  #   "Version" : "2012-10-17",
  #   "Statement" : [
  #     {
  #       "Sid" : "DenyUnSecureCommunications",
  #       "Effect" : "Deny",
  #       "Principal" : "*",
  #       "Action" : "s3:*",
  #       "Resource" : [
  #         aws_s3_bucket.default.arn
  #       ],
  #       "Condition" : {
  #         "Bool" : {
  #           "aws:SecureTransport" : "false"
  #         }
  #       }
  #     }
  #   ]
  # }])

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
