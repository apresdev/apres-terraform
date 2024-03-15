resource "aws_kms_key_policy" "default" {
  # conditionally create the policy if the KMS key ARN is not provided
  count  = length(var.kms_key_arn) == 0 ? 1 : 0
  key_id = aws_kms_key.cwl[0].id
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
        Sid    = "Allow CloudWatch to use the key",
        Effect = "Allow",
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "cwl" {
  # conditinally create the KMS key if the KMS key ARN is not provided
  count                   = length(var.kms_key_arn) == 0 ? 1 : 0
  description             = "${var.name} CloudWatch Logs key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(
    local.tags,
    {
      Name = "${var.name} CloudWatch Logs Key"
    },
  )
}
