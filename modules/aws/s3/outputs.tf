output "bucket_arn" {
  value       = aws_s3_bucket.default.arn
  description = "The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`."
}

output "bucket_name" {
  value       = aws_s3_bucket.default.bucket
  description = "The name of the S3 bucket."
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.default.bucket_domain_name
  description = "The bucket domain name. Will be of format `bucketname.s3.amazonaws.com`."
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.default.bucket_regional_domain_name
  description = "The bucket regional domain name. Will be of format `bucketname.s3.region.amazonaws.com`."
}

output "default_bucket_policy" {
  value       = data.aws_iam_policy_document.deny_unsecure_communications.json
  description = <<EOF
  See comment on the variable `set_default_bucket_policy` for how to use this output.
  EOF
}