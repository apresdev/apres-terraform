output "alarm_arn" {
  description = "The ARN of the CloudWatch Alarm"
  value       = module.alarm.alarm_arn
}

output "alarm_id" {
  description = "The id of the CloudWatch Alarm"
  value       = module.alarm.alarm_id
}