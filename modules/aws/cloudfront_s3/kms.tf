resource "aws_kms_key_policy" "default" {
  key_id = aws_kms_key.default.id
  # The first statement is required to allow the CloudWatch service to use the key.
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid    = "Allow account to use the key",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow CloudFront to use the key",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
        ],
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" : aws_cloudfront_distribution.default.arn
          }
        }
      }
    ]
  })
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