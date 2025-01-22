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

output "security_group_id" {
  description = "The ID of the security group created for the lambda function if VPC attachment is used, else null."
  value       = local.use_vpc ? aws_security_group.default[0].id : null
}

output "security_group_arn" {
  description = "The ARN of the security group created for the lambda function if VPC attachment is used, else null."
  value       = local.use_vpc ? aws_security_group.default[0].arn : null
}

output "deadletter_queue_id" {
  description = "The ID of the dead letter queue."
  value       = aws_sqs_queue.deadletter.id
}

output "deadletter_queue_arn" {
  description = "The ARN of the dead letter queue."
  value       = aws_sqs_queue.deadletter.arn
}