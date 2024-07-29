output "kms_arn" {
  value       = aws_kms_key.cwl.arn
  description = "The ARN of the KMS key used to encrypt the CloudWatch Log Group"
}

output "kms_alias" {
  value       = aws_kms_alias.cwl.arn
  description = "The ARN of the KMS alias used to encrypt the CloudWatch Log Group"
}

output "api_gateway_cloudwatch_logs_role_arn" {
  description = "ARN of the API Gateway CloudWatch Logs role, or empty string if enable_api_gateway_logging = false"
  value       = var.enable_api_gateway_logging ? aws_iam_role.apigw_cwl[0].arn : ""
}