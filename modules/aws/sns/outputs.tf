output "topic_name" {
  value       = aws_sns_topic.default.name
  description = "The name of the SNS topic."
}

output "topic_arn" {
  value       = aws_sns_topic.default.arn
  description = "The ARN of the SNS topic."
}
