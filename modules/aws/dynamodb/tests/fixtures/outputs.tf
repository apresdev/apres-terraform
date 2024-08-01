output "table_arn" {
  value = module.dynamodb.table_arn
}

output "table_name" {
  value = module.dynamodb.table_name
}

output "stream_arn" {
  value = module.dynamodb.stream_arn
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

