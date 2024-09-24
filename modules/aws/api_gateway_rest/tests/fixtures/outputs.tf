output "arn" {
  description = "The ARN of the API GW"
  value       = module.apigw.apigw_arn
}

output "id" {
  description = "The ID of the API GW"
  value       = module.apigw.apigw_id
}

output "invoke_url" {
  description = "The URL to invoke the API via the stage"
  value       = module.apigw.apigw_stage_invoke_url
}