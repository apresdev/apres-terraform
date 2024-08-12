output "queue_name" {
  value       = aws_sqs_queue.default.name
  description = "The name of the SQS queue."
}

output "queue_arn" {
  value       = aws_sqs_queue.default.arn
  description = "The ARN of the SQS queue."
}

output "queue_url" {
  value       = aws_sqs_queue.default.id
  description = "The ARN of the SQS queue."
}

output "deadletter_queue_name" {
  value       = aws_sqs_queue.deadletter.name
  description = "The name of the SQS queue."
}

output "deadletter_queue_arn" {
  value       = aws_sqs_queue.deadletter.arn
  description = "The ARN of the SQS queue."
}

output "error_rate_alarm_arns" {
  value       = aws_cloudwatch_metric_alarm.error_rate[*].arn
  description = "The ARN of error rate alarms."
}

output "historical_latency_alarm_arns" {
  value       = aws_cloudwatch_metric_alarm.historical_latency[*].arn
  description = "The ARN of error rate alarms."
}

output "projected_latency_alarm_arns" {
  value       = aws_cloudwatch_metric_alarm.projected_latency[*].arn
  description = "The ARN of error rate alarms."
}
