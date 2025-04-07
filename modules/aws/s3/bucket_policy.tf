locals {
  # Only create the replication policy on the destination bucket if it's in a different account,
  # else it'll fail to create with a resource error
  add_replication_policy = var.replication_destination_config.enabled && var.replication_destination_config.source_bucket_in_other_account
}

data "aws_iam_policy_document" "replication_destination" {
  count = local.add_replication_policy ? 1 : 0
  # Ideally we'd use Principal: {"AWS: "role-arn"} in the first two statements, but when deployed
  # S3 looks up the remote role and if it doesn't exist fails with an "Invalid principal" error.
  # That introduces a circular dependency because the source
  # bucket/stack can't be deployed until the destination bucket exists, and then the destination bucket/stack
  # can't be deployed until the source role exists. So we bypass that with the condition, which amounts to the
  # same restriction but without the circular dependency.
  statement {
    sid    = "SetPermissionsForObjects"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
    ]
    resources = [
      "${aws_s3_bucket.default.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = [var.replication_destination_config.source_service_role_arn]
    }
  }
  statement {
    sid    = "SetVersioningOnBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
    ]

    resources = [
      aws_s3_bucket.default.arn
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = [var.replication_destination_config.source_service_role_arn]
    }
  }
  # This is a copy of the deny_unsecure_communications policy below, it's difficult to attempt to
  # conditionally merge documents.
  statement {
    sid    = "DenyUnSecureCommunications"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.default.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "deny_unsecure_communications" {
  statement {
    sid    = "DenyUnSecureCommunications"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.default.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Ensure data is transported from the S3 bucket securely
resource "aws_s3_bucket_policy" "default" {
  count  = var.set_default_bucket_policy ? 1 : 0
  bucket = aws_s3_bucket.default.id
  policy = local.add_replication_policy ? data.aws_iam_policy_document.replication_destination[0].json : data.aws_iam_policy_document.deny_unsecure_communications.json
}
