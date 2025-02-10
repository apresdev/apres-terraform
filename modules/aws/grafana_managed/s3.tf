module "dashboards-bucket" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.1.1"
  name        = "grafana-dashboards"
  environment = var.environment
  versioning  = true
  application = var.application
  component   = var.component
  owner       = var.owner
  # Creating our own lifecycle rules
  lifecycle_rule = {
    enabled = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  bucket = module.dashboards-bucket.bucket_id

  # Keep backups for max one year or the bucket size will grow forever
  # since backups are hourly.
  rule {
    id     = "backup"
    status = "Enabled"
    filter {
      prefix = "backup/" # hard coded in the Configurator
    }
    expiration {
      days = 365
    }
  }
  # Applies to the whole bucket
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
}

# Store all files into S3, in the "apres" key.
resource "aws_s3_object" "grafana_dashboards" {
  #checkov:skip=CKV_AWS_186: Using the S3 default key for encryption.
  for_each = fileset("${path.module}/dashboards", "*.json")
  bucket   = module.dashboards-bucket.bucket_id
  source   = "${path.module}/dashboards/${each.value}"
  key      = "${local.dashboard_s3_prefix}/${each.value}"
}

resource "aws_s3_object" "custom_dashboards" {
  for_each = var.custom_dashboards
  bucket   = module.dashboards-bucket.bucket_id
  source   = each.value
  key      = "${var.custom_dashboard_folder_name}/${each.key}.json"
}