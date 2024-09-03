output "grafana_url" {
  description = "The URL of the Grafana workspace"
  value       = "https://${aws_grafana_workspace.default.endpoint}"
}

output "grafana_arn" {
  description = "The ARN of the Grafana workspace"
  value       = aws_grafana_workspace.default.arn
}

output "grafana_version" {
  description = "The version of the Grafana workspace"
  value       = aws_grafana_workspace.default.grafana_version
}

output "notifications_sns_topic_arn" {
  description = "SNS Topic ARN to which notifications can be sent"
  value       = aws_sns_topic.default.arn
}