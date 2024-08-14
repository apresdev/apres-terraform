# Creates a signing profile for lambda.
resource "aws_signer_signing_profile" "default" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "ApresLambdaSigningProfile"

  signature_validity_period {
    value = 3
    type  = "MONTHS"
  }

  tags = local.tags
}

# Creates a signing configuration that requires the signing profile defined above.
resource "aws_lambda_code_signing_config" "default" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.default.arn,
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }

}

# Save the lambda signing config arn in a well known parameter.  This is needed by the lambda module to re-use the same signing 
# configuration across lambda functions, rather than creating a configuration per function.
#
# We need the parameter because the only way to lookup a data.aws_lambda_code_signing_config is with the arn and a portion of the arb is
# auto-generated after the terraform completes (i.e.)

# data "aws_lambda_code_signing_config" "existing_csc" {
#  arn = "arn:aws:lambda:${var.aws_region}:${var.aws_account}:code-signing-config:csc-0f6c334abcdea4d8b"
#}
#
# The id csc-0f6c334abcdea4d8b is completely random, as such there is no way to look this up based on convention.  So we need a paramter to 
# store and retrieve this at deploy time.
resource "aws_ssm_parameter" "default" {
  name        = "apres/lambda/lambda-signing-config-arn"
  description = "The ARN for the lambda signing configuration."
  type        = "SecureString"
  value       = aws_lambda_code_signing_config.default.arn

  #checkov:skip=CKV_AWS_337:"Ensure SSM parameters are using KMS CMK"

  tags = merge(
    local.tags,
    tomap({
      Name = "apres/lambda/lambda-signing-config-arn"
    })
  )
}
