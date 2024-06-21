output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "bucket_domain_name" {
  value = module.s3.bucket_domain_name
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

output "default_bucket_policy" {
  value = module.s3.default_bucket_policy
}