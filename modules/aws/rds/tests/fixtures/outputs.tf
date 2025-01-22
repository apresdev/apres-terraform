output "endpoint" {
  value = module.rds.endpoint
}

output "master_password_secret_arn" {
  value = module.rds.master_password_secret_arn
}

output "cluster_id" {
  value = module.rds.cluster_id
}

output "port" {
  value = module.rds.port
}

output "lambda_function_arn" {
  value = module.lambda.lambda_function_arn
}

output "lambda_function_name" {
  value = module.lambda.lambda_function_name
}