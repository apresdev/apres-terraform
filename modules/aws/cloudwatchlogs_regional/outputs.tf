output "kms_arn" {
  value       = aws_kms_key.cwl.arn
  description = "The ARN of the KMS key used to encrypt the CloudWatch Log Group"
}

output "kms_alias" {
  value       = aws_kms_alias.cwl.arn
  description = "The ARN of the KMS alias used to encrypt the CloudWatch Log Group"
}