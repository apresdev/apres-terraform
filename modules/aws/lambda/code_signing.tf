# Upload the unsigned zipped source file to the lambda artifacts bucket.
# This is required for the code signing job below.
resource "aws_s3_object" "unsigned" {
  bucket = local.artifact_bucket
  key    = "unsigned/${local.name}.zip"
  source = local.artifact

  tags = merge(
    local.tags,
    tomap({
      Name = "unsigned/${local.name}.zip"
    })
  )

  depends_on = [
    data.archive_file.lambda
  ]
}

# Create a job to sign the artifacts.
# This signs the S3 object that was created above and places it in the signed prefix location.
resource "aws_signer_signing_job" "default" {
  profile_name = data.aws_ssm_parameter.signing_profile_name.value

  source {
    s3 {
      bucket  = local.artifact_bucket
      key     = aws_s3_object.unsigned.id
      version = aws_s3_object.unsigned.version_id
    }
  }

  destination {
    s3 {
      bucket = local.artifact_bucket
      prefix = "signed/"
    }
  }

  ignore_signing_job_failure = false
}
