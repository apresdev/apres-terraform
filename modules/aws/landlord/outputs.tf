output "acm_public_cert_console_arn" {
  description = "The ARN of the ACM certificate for the console."
  value       = module.acm_public_cert_console.certificate_arn
}

output "acm_public_cert_api_arn" {
  description = "The ARN of the ACM certificate for the API."
  value       = module.acm_public_cert_console.certificate_arn
}

output "api_gateway_arn" {
  description = "The ARN of the API Gateway."
  value       = module.landlord_api_gateway.apigw_arn
}

output "api_gateway_invoke_url" {
  description = "The invoke URL of the API Gateway."
  value       = module.landlord_api_gateway.apigw_stage_invoke_url
}

output "cdc_sync_queue_name" {
  description = "The name of the CDC sync SQS queue."
  value       = module.landlord_sync_queue.queue_name
}

output "cdc_sync_queue_arn" {
  description = "The ARN of the CDC sync SQS queue."
  value       = module.landlord_sync_queue.queue_arn
}

output "console_domain_name" {
  description = "The domain name of the console."
  value       = local.console_domain_name
}

output "api_domain_name" {
  description = "The domain name of the API."
  value       = local.api_domain_name
}

output "console_ecs_cluster_name" {
  description = "The name of the ECS cluster for the console."
  value       = module.landlord_console_ecs.ecs_cluster_name
}

output "console_ecs_service_name" {
  description = "The name of the ECS service for the console."
  value       = module.landlord_console_ecs.ecs_service_name
}

output "console_load_balancer_arn" {
  description = "The ARN of the load balancer for the console."
  value       = module.landlord_console_ecs.load_balancer_arn
}

output "console_load_balancer_fqdn" {
  description = "The FQDN of the load balancer for the console."
  value       = module.landlord_console_ecs.load_balancer_dns_name
}

output "api_ecs_cluster_name" {
  description = "The name of the ECS cluster for the API."
  value       = module.landlord_api_ecs.ecs_cluster_name
}

output "api_ecs_service_name" {
  description = "The name of the ECS service for the API."
  value       = module.landlord_api_ecs.ecs_service_name
}

output "api_load_balancer_arn" {
  description = "The ARN of the load balancer for the API."
  value       = module.landlord_api_ecs.load_balancer_arn
}

output "api_load_balancer_fqdn" {
  description = "The FQDN of the load balancer for the API."
  value       = module.landlord_api_ecs.load_balancer_dns_name
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito user pool."
  value       = aws_cognito_user_pool.default.arn
}
output "cognito_user_pool_id" {
  description = "The ID of the Cognito user pool."
  value       = aws_cognito_user_pool.default.id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito user pool client."
  value       = aws_cognito_user_pool_client.default.id
}