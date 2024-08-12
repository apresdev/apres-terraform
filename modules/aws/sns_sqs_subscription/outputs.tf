output "subscription_name" {
  value       = aws_sns_topic_subscription.default.arn
  description = "The ARN of the subcription."
}
