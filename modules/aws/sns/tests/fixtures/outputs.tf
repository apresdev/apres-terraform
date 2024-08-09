output "topic_arn" {
  value = module.sns.topic_arn
}

output "topic_name" {
  value = module.sns.topic_name
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}
