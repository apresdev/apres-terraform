output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id

}
output "lambda_function_arn" {
  value = module.lambda.lambda_function_arn
}

output "lambda_function_name" {
  value = module.lambda.lambda_function_name
}
