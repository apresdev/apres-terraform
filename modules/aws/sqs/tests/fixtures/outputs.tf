output "queue_arn" {
  value = module.sqs.queue_arn
}

output "queue_name" {
  value = module.sqs.queue_name
}

output "deadletter_queue_arn" {
  value = module.sqs.deadletter_queue_arn
}

output "deadletter_queue_name" {
  value = module.sqs.deadletter_queue_name
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

output "error_rate_alarm_arns" {
  value = module.sqs.error_rate_alarm_arns
}

output "historical_latency_alarm_arns" {
  value = module.sqs.historical_latency_alarm_arns
}

output "projected_latency_alarm_arns" {
  value = module.sqs.projected_latency_alarm_arns
}
