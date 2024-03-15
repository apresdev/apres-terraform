output "cwl_arn" {
  value       = resource.aws_cloudwatch_log_group.default.arn
  description = "The ARN of the CloudWatch Log Group"
}

output "kms_arn" {
  value       = aws_kms_key.cwl[0].arn
  description = "The ARN of the KMS key used to encrypt the CloudWatch Log Group"
}