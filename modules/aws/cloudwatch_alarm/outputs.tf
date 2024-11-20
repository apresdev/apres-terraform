output "alarm_arn" {
  description = "The ARN of the CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.standard_alarm.arn
}

output "alarm_name" {
  # In the AWS API there is no ID, so we expose the alarm name.
  description = "The name of the CloudWatch Alarm."
  value       = aws_cloudwatch_metric_alarm.standard_alarm.id
}