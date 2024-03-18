output "cwl_arn" {
  value       = resource.aws_cloudwatch_log_group.default.arn
  description = "The ARN of the CloudWatch Log Group"
}
