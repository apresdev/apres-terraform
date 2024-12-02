output "lambda_artifacts_bucket_name" {
  description = "Name of the lambda artifacts bucket"
  value       = module.s3_artifacts.bucket_name
}

output "signing_profile_name" {
  description = "Value of the ssm parameter for the signing profile name"
  value       = aws_ssm_parameter.signing_profile_name.value
}

output "signing_config_name_ssm_parameter" {
  description = "Name of the SSM Parameter containing the signing profile name"
  value       = local.signing_profile_ssm_parameter
}

output "signing_config_arn" {
  description = "Value of the ssm parameter for the signing config arn"
  value       = aws_ssm_parameter.default.value
}

output "signing_config_arn_ssm_parameter" {
  description = "Name of the SSM Parameter containing the code signing config arn"
  value       = local.signing_arn_ssm_parameter
}