output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.default.id
  description = "ID of the CloudFront distribution"
}

output "cloudfront_distribution_domain_name" {
  value       = aws_cloudfront_distribution.default.domain_name
  description = "Domain name of the CloudFront distribution"
}

output "cloudfront_distribution_hosted_zone_id" {
  value       = aws_cloudfront_distribution.default.hosted_zone_id
  description = "Hosted zone ID of the CloudFront distribution, required for creating alias records."
}

output "cloudfront_distribution_arn" {
  value       = aws_cloudfront_distribution.default.arn
  description = "ARN of the CloudFront distribution"
}

output "s3_bucket_name" {
  value       = module.s3.bucket_name
  description = "Name of the S3 bucket containing the website content"
}

output "s3_bucket_domain_name" {
  value       = module.s3.bucket_domain_name
  description = "Global domain name of the S3 bucket containing the website content"
}

output "s3_bucket_regional_domain_name" {
  value       = module.s3.bucket_regional_domain_name
  description = "Regional domain name of the S3 bucket containing the website content"
}

output "s3_logs_bucket_name" {
  value       = module.s3_logs.bucket_name
  description = "Name of the S3 bucket containing the CloudFront logs"
}

output "s3_logs_bucket_domain_name" {
  value       = module.s3_logs.bucket_domain_name
  description = "Global domain name of the S3 bucket containing the CloudFront logs"
}

output "s3_logs_bucket_regional_domain_name" {
  value       = module.s3_logs.bucket_regional_domain_name
  description = "Regional domain name of the S3 bucket containing the CloudFront logs"
}

output "waf_arn" {
  value       = var.waf_arn == "" ? module.waf[0].waf_arn : var.waf_arn
  description = "ARN of the WAF attached to the CloudFront distribution"
}

output "s3_kms_key_arn" {
  value       = aws_kms_key.default.arn
  description = "ARN of the KMS key used to encrypt the S3 bucket"
}

output "replication_source_service_role_arn" {
  value       = var.replication_source_config.enabled ? module.s3.replication_source_service_role_arn : null
  description = <<EOF
    The IAM role name for the replication source.  This is only created if replication is enabled and this
    is the source bucket. This Role ARN is needed to allow the destination bucket to replicate from this bucket.
  EOF
}