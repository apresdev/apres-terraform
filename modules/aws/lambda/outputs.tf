output "iam_role_arn" {
  description = "The ARN of the IAM role created for the lambda function"
  value       = aws_iam_role.default.arn
}

output "iam_role_name" {
  description = "The name of the IAM role created for the lambda function"
  value       = aws_iam_role.default.name
}

output "lambda_function_arn" {
  description = "The ARN of the lambda function"
  value       = aws_lambda_function.default.arn
}

output "lambda_function_name" {
  description = "The name of the lambda function"
  value       = aws_lambda_function.default.function_name
}
