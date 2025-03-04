output "apigw_arn" {
  description = "The ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.default.arn
}

output "apigw_execution_arn" {
  description = "The Execution ARN of the API Gateway REST API, used in Lambda permissions."
  value       = aws_api_gateway_rest_api.default.execution_arn
}

output "apigw_id" {
  description = "The ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.default.id
}

output "apigw_root_resource_id" {
  description = "The Root Resource ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.default.root_resource_id
}

output "apigw_stage_arn" {
  description = "The ARN of the API Gateway REST API Stage"
  value       = aws_api_gateway_stage.default.arn
}

output "apigw_stage_id" {
  description = "The ID of the API Gateway REST API Stage"
  value       = aws_api_gateway_stage.default.id
}

output "apigw_stage_execution_arn" {
  description = "The Execution ARN of the API Gateway REST API Stage, used in Lambda permissions."
  value       = aws_api_gateway_stage.default.execution_arn
}

output "apigw_stage_invoke_url" {
  description = "The URL to invoke the API via the stage"
  value       = aws_api_gateway_stage.default.invoke_url
}

output "apigw_custom_domain_name" {
  description = "The custom domain name of the API Gateway REST API, or empty string if not created"
  value       = local.do_route53 ? aws_api_gateway_domain_name.default[0].regional_domain_name : ""
}