output "binary_path" {
  value = local.binary_path
}

output "lambda_arn" {
  value = module.lambda.lambda_function_arn
}

