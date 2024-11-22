output "event_rule_arn" {
  value       = aws_cloudwatch_event_rule.schedule.arn
  description = "The ARN for the generated CloudWatch Event Rule."
}

output "event_rule_name" {
  value       = aws_cloudwatch_event_rule.schedule.name
  description = "The Name for the generated CloudWatch Event Rule."
}