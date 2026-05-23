output "security_hub_findings_sns_topic_arn" {
  value = local.alerting_enabled ? module.alerting[0].sns_topic_arns[0] : ""
}