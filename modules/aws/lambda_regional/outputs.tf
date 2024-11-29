output "lambda_artifacts_bucket_name" {
  description = "Name of the lambda artifacts bucket"
  value       = module.s3_artifacts.bucket_name
}

output "signing_profile_name" {
  description = "Value of the ssm parameter for the signing profile name"
  value       = aws_ssm_parameter.signing_profile_name.value
}

output "signing_config_arn" {
  description = "Value of the ssm parameter for the signing config arn"
  value       = aws_ssm_parameter.default.value
}