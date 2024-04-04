output "cwl_arn" {
  value       = module.cloudwatchlogs.cwl_arn
  description = "The ARN of the CloudWatch Log Group"
}