output "cloudfront_distribution_id" {
  value = module.cloudfront_s3.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront_s3.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_arn" {
  value = module.cloudfront_s3.cloudfront_distribution_arn
}

output "s3_bucket_name" {
  value = module.cloudfront_s3.s3_bucket_name
}

output "s3_logs_bucket_name" {
  value = module.cloudfront_s3.s3_logs_bucket_name
}

output "waf_arn" {
  value = module.cloudfront_s3.waf_arn
}