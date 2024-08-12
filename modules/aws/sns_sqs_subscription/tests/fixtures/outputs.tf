output "topic_arn" {
  value = module.sns.topic_arn
}

output "queue_arn" {
  value = module.sqs.queue_arn
}

output "queue_url" {
  value = module.sqs.queue_url
}
