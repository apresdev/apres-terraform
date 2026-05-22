# Create an S3 bucket where the signed and unsigned lambda source will be placed.
# The lambda module will automatically upload lambda artifacts to this bucket to be signed and will automatically configure the lamda
# resource to pull signed artifacts from the same S3 bucket.
module "s3_artifacts" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source = "https://github.com/apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/4.3.1"

  name = "lambda-artifacts"

  environment = var.environment
  component   = var.component
  application = var.application
  owner       = var.owner

  lifecycle_rule = {
    enabled = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  bucket = module.s3_artifacts.bucket_id

  rule {
    id     = "ApresLifeCycleRule"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    transition {
      days          = 1
      storage_class = "INTELLIGENT_TIERING"
    }
  }
  rule {
    id     = "DeleteUnsignedArtifacts"
    status = "Enabled"
    filter {
      prefix = "unsigned/"
    }
    expiration {
      days = 30
    }
  }
}
