output "table_name" {
  value       = aws_dynamodb_table.default.name
  description = "The name of the DynamoDB table."
}

output "table_arn" {
  value       = aws_dynamodb_table.default.arn
  description = "The ARN of the DynamoDB table."
}

output "stream_arn" {
  value       = aws_dynamodb_table.default.stream_arn
  description = "ARN of the Table Stream. Only available when stream_enabled = true."
}
