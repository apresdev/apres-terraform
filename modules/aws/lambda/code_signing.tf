# Upload the unsigned zipped source file to the lambda artifacts bucket.
# This is required for the code signing job below.
resource "aws_s3_object" "unsigned" {
  bucket = local.artifact_bucket
  key    = local.artifact_key
  source = local.artifact

  tags = merge(
    local.tags,
    tomap({
      Name = local.artifact_key
    })
  )

  # Force the upload if the file changes locally. Use source_hash to work around
  # encryption limitations with etag. The value is stored in state, not in S3, so
  # there is a possibility of uploading it more frequently than necessary, but that's
  # better than missing an upload.
  source_hash = local.artifact_hash

  depends_on = [
    data.archive_file.lambda
  ]

  # Check to ensure we have a source of artifact, since we can't (yet) check that in the variable definition.
  lifecycle {
    precondition {
      condition     = var.source_file != "" || var.zip_file != ""
      error_message = "One of `source_file` or `zip_file` must be set."
    }
  }
}

# Create a job to sign the artifacts.
# This signs the S3 object that was created above and places it in the signed prefix location.
moved {
  from = aws_signer_signing_job.default
  to   = aws_signer_signing_job.default[0]
}
resource "aws_signer_signing_job" "default" {
  count        = var.disable_code_signing ? 0 : 1
  profile_name = data.aws_ssm_parameter.signing_profile_name[0].value

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
