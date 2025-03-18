output "bucket_arn" {
  value       = aws_s3_bucket.default.arn
  description = "The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`."
}

output "bucket_name" {
  value       = aws_s3_bucket.default.id
  description = "The name of the S3 bucket."
}

output "bucket_id" {
  value       = aws_s3_bucket.default.id
  description = "The ID of the bucket, same as the name."
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

output "replication_source_service_role_arn" {
  value       = var.replication_source_config.enabled ? aws_iam_role.replication_source[0].arn : null
  description = <<EOF
    The IAM role name for the replication source.  This is only created if replication is enabled and this
    is the source bucket. This Role ARN is needed to allow the destination bucket to replicate from this bucket.
  EOF
}

output "replication_bucket_policy" {
  value       = var.replication_destination_config.enabled == true && var.set_default_bucket_policy == false ? data.aws_iam_policy_document.replication_destination[0].json : null
  description = <<EOF
    The bucket policy json for the replication destination bucket. This is only created if replication is enabled and
    `set_default_bucket_policy` is false, in which case it is the calling stack's responsibility to add this
    policy document to the bucket policy, else replication will not work.
  EOF
}