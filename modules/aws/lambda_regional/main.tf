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

