locals {
  # calculate the the KMS Key ARN used in this bucket, for replication purposes.
  source_kms_key_arn = var.encryption_kms_key_arn == "" ? "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/s3" : var.encryption_kms_key_arn

  owner_translation = var.replication_source_config.owner_translation && var.replication_source_config.destination_account_id != data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "s3_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# The next set of IAM roles/policies are for replication, if this is the source bucket.

# Role for replication, if this bucket is the source.
# Purposely not using name_prefix here, since we need it to be stable for the
# destination bucket. Also, since a bucket name is unique per region in this module,
# we don't expect to create this role twice in the same region.
resource "aws_iam_role" "replication_source" {
  count              = var.replication_source_config.enabled ? 1 : 0
  name               = "${local.name}-${data.aws_region.current.name}-ReplicationSource"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

# Policy for replication, allows from this bucket to the specified destination
data "aws_iam_policy_document" "replication_source" {
  count = var.replication_source_config.enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.default.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.default.arn}/${var.replication_source_config.replication_prefix}*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
    ]
    resources = ["${var.replication_source_config.destination_bucket_arn}/${var.replication_source_config.replication_prefix}*"]
  }
  # Allow replication of encrypted objects on the source bucket
  # See https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html#replications
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        var.encryption_sse_algorithm == "SSE-S3" ? "${aws_s3_bucket.default.arn}" : "${aws_s3_bucket.default.arn}/${var.replication_source_config.replication_prefix}*"
      ]
    }
    resources = [local.source_kms_key_arn]
  }
  # Allow replication of encrypted objects on the destination bucket, using the destination bucket's
  # KMS algorithm and key.
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*"
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${var.replication_source_config.destination_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        var.replication_source_config.destination_encryption_sse_algorithm == "SSE-S3" ? "${var.replication_source_config.destination_bucket_arn}" : "${var.replication_source_config.destination_bucket_arn}/${var.replication_source_config.replication_prefix}*"
      ]
    }
    resources = [
      var.replication_source_config.destination_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "replication_source" {
  count       = var.replication_source_config.enabled ? 1 : 0
  name_prefix = local.name
  policy      = data.aws_iam_policy_document.replication_source[0].json
}

resource "aws_iam_role_policy_attachment" "replication_source" {
  count      = var.replication_source_config.enabled ? 1 : 0
  role       = aws_iam_role.replication_source[0].name
  policy_arn = aws_iam_policy.replication_source[0].arn
}

resource "aws_s3_bucket_replication_configuration" "replication_source" {
  count = var.replication_source_config.enabled ? 1 : 0

  # Ensure versioning is enabled before we enable replication
  lifecycle {
    precondition {
      condition     = var.replication_source_config.enabled == true && var.versioning == false ? false : true
      error_message = "Versioning must be enabled for replication to succeed."
    }
    precondition {
      condition     = var.replication_source_config.enabled == true && var.replication_source_config.destination_encryption_sse_algorithm == "SSE-KMS" && var.replication_source_config.destination_kms_key_arn == "" ? false : true
      error_message = "Replication to a destination bucket with SSE-KMS requires a KMS key ID, cannot use the default aws/s3 key."
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.default
  ]

  bucket = aws_s3_bucket.default.id
  role   = aws_iam_role.replication_source[0].arn

  rule {
    delete_marker_replication {
      status = var.replication_source_config.replicate_delete_markers ? "Enabled" : "Disabled"
    }
    filter {
      prefix = var.replication_source_config.replication_prefix
    }
    status = "Enabled"
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
    destination {
      # if anything in the ARN is upper case it'll fail with a weird error.
      bucket = lower(var.replication_source_config.destination_bucket_arn)
      encryption_configuration {
        replica_kms_key_id = var.replication_source_config.destination_kms_key_arn
      }
      metrics {
        status = "Enabled"
      }
      # change the owner to the destination bucket, if configured to and the destination account is
      # different from the source. Need both the account and access_control_translation to be set.
      account = local.owner_translation ? var.replication_source_config.destination_account_id : null
      dynamic "access_control_translation" {
        for_each = local.owner_translation ? [1] : []
        content {
          owner = "Destination"
        }
      }
    }
  }
}