output "grafana_url" {
  description = "The URL of the Grafana workspace"
  value       = module.grafana.grafana_url
}

output "grafana_arn" {
  description = "The ARN of the Grafana workspace"
  value       = module.grafana.grafana_arn
}

output "grafana_version" {
  description = "The version of the Grafana workspace"
  value       = module.grafana.grafana_version
}

output "notifications_sns_topic_arn" {
  description = "SNS Topic ARN to which notifications can be sent"
  value       = module.grafana.notifications_sns_topic_arn
}