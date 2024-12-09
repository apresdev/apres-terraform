output "sns_topic_arns" {
  description = "List of ARNs for the SNS topics created for alerting."
  value       = [for topic in aws_sns_topic.default : topic.arn]
}