output "rule_name" {
  description = "Name of the CloudWatch Event Rule"
  value       = module.ecs_events.rule_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.ecs_events.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.ecs_events.lambda_function_name
}

output "cluster_name" {
  value = module.goodbyeworld.ecs_cluster_name
}

output "service_name" {
  value = module.goodbyeworld.ecs_service_name
}