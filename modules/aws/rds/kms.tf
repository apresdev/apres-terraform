resource "aws_kms_key" "default" {
  description             = "KMS key for RDS instance ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(
    local.tags,
    {
      "Name" = local.name
    }
  )
}

resource "aws_kms_key_policy" "default" {
  key_id = aws_kms_key.default.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowRDS"
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        },
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowIAMUsers"
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "kms:*"
        ]
        Resource = "*"
      }
    ]
  })
}