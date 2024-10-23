output "alerts_sns_topic_arn" {
  description = "The ARN of the SNS Topic for alerts, or empty string if it does not exist in this region."
  value       = local.enable_chat_alerts ? module.alerting.sns_topic_arn : ""
}