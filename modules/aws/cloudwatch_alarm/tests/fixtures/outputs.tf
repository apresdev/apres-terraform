output "alarm_arn" {
  description = "The ARN of the CloudWatch Alarm"
  value       = module.alarm.alarm_arn
}

output "alarm_name" {
  description = "The name of the CloudWatch Alarm"
  value       = module.alarm.alarm_name
}