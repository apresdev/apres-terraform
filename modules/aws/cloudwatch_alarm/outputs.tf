output "alarm_arn" {
  description = "The ARN of the CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.standard_alarm.arn
}

output "alarm_id" {
  description = "The ID of the CloudWatch Alarm, which is also the name."
  value       = aws_cloudwatch_metric_alarm.standard_alarm.id
}

output "alarm_name" {
  description = "The name of the CloudWatch Alarm, which is also the ID."
  value       = aws_cloudwatch_metric_alarm.standard_alarm.id
}