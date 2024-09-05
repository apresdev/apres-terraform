output "table_name" {
  value = module.dynamodb.table_name
}

output "queue_url" {
  value = module.sqs.queue_url
}

output "lambda_artifact" {
  value = module.dynamodb_sns_publisher.lambda_artifact
}