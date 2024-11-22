output "lambda_arn" {
  value = module.lambda.lambda_function_arn
}

output "event_rule_arn" {
  value = module.scheduler.event_rule_arn
}

output "event_rule_name" {
  value = module.scheduler.event_rule_name
}