variable "environment" {
  description = "Environment name, used for tagging AWS resources, and in the bucket name."
  type        = string
  default     = "dev"
}

# The following naming rules apply for general purpose buckets.
# - Bucket names must be between 3 (min) and 63 (max) characters long.
#   - AWS Account ID is ~ 12-characters
#   - AWS Regions are at most 14 characters
#   - The environment is variable, but lets assume at most 10 charactesr (i.e. "production")
#   - We include 3 hyphens between account id, environment, region, and name.
# - Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-).
# - Bucket names must begin and end with a letter or number.
# - Bucket names must not contain two adjacent periods.
# - Bucket names must not be formatted as an IP address (for example, 192.168.5.4).
# - Bucket names must not start with the prefix xn--.
# - Bucket names must not start with the prefix sthree- and the prefix sthree-configurator.
# - Bucket names must not end with the suffix -s3alias. This suffix is reserved for access point alias names. For more
#   information, see Using a bucket-style alias for your S3 bucket access point.
# - Bucket names must not end with the suffix --ol-s3. This suffix is reserved for Object Lambda Access Point alias
#   names. For more information, see How to use a bucket-style alias for your S3 bucket Object Lambda Access Point.
# - Bucket names must be unique across all AWS accounts in all the AWS Regions within a partition. A partition is a
#   grouping of Regions. AWS currently has three partitions: aws (Standard Regions), aws-cn (China Regions), and
#   aws-us-gov (AWS GovCloud (US)).
# - A bucket name cannot be used by another AWS account in the same partition until the bucket is deleted.
# - Buckets used with Amazon S3 Transfer Acceleration can't have dots (.) in their names. For more information about
#   Transfer Acceleration, see Configuring fast, secure file transfers using Amazon S3 Transfer Acceleration.
variable "name" {
  description = "Name of the bucket"
  type        = string
  validation {
    condition     = length(var.name) >= 3 && length(var.name) < 24
    error_message = "Name length must be between 3 and 34 characters."
  }
  validation {
    condition     = can(regex("^[a-z-0-9][a-z0-9-]*[a-z-0-9]$", var.name))
    error_message = "The name must start with a letter or number, end with a letter or number, and can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "versioning" {
  description = "Flag to indicate if object versioning is enabled.  Defaults to true due to best practice: Ensure AWS S3 object versioning is enabled."
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = <<EOF
  Flag to indicate if MFA delete is enabled. While this should be set to true, there is a race condition
  where the deploy fails to create bucket versioning if this is set to true. If you need this set to true, then
  you'll need to deploy it in two steps. First create the bucket with mfa_delete=false, then set mfa_delete=true
  and deploy again.
  EOF
  type        = bool
  default     = false
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "set_default_bucket_policy" {
  description = <<EOF
  A bucket policy can only be set in one place, or it'll get overwritten. For some cases you may need to add statements
  that include ARN's of other resources. If that's the case, set this to false, and then use the output
  `default_bucket_policy` to include in your own policy.

  If replication is desired and this is set to false, you must include the `replication_bucket_policy` output in your
  bucket policy as well, else replication will not succeed!

  For example, in your code:
    ```hcl
    module "s3" {
      # ...
      set_default_bucket_policy = false
    }

    data "aws_iam_policy_document" "default" {
      # your statements here
    }

    resource "aws_s3_bucket_policy" "default" {
      bucket = module.s3.bucket_name
      policy = data.aws_iam_policy_document.default.json
      source_policy_documents = [ module.s3.default_bucket_policy ]
    }
    ```
    The statement SID's must be unique, the SID used in the default policy is "DenyUnSecureCommunications".
  EOF
  type        = bool
  default     = true
}

variable "encryption_sse_algorithm" {
  description = <<EOF
  The server-side encryption algorithm to use. Defaults to 'aws:kms'. Descriptions of the options from
  the AWS docs are, with the attributes passed into the API brackets:
  * `SSE-S3` (AES256): Server-side encryption with Amazon S3 managed keys. This is not supported on destination
     buckets in replication scenarios.
  * `SSE-KMS` (aws:kms): Server-side encryption with AWS Key Management Service keys
  * `DSSE-KMS` (aws:kms:dsse): Dual-layer server-side encryption with AWS KMS keys
  EOF
  type        = string
  default     = "SSE-KMS"
  validation {
    condition     = var.encryption_sse_algorithm == "SSE-S3" || var.encryption_sse_algorithm == "SSE-KMS" || var.encryption_sse_algorithm == "DSSE-KMS"
    error_message = "encryption_sse_algorithm must be SSE-S3, SSE-KMS or DSSE-KMS."
  }
}

variable "encryption_kms_key_arn" {
  description = <<EOF
  The ARN of the KMS key to use for server-side encryption. If not provided,
  the default AWS managed key 'aws/s3' will be used.

  Note that if this bucket is the destination for replication, a KMS key must be specified.
  EOF
  type        = string
  default     = ""
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "lifecycle_rule" {
  description = <<EOF
  S3 Lifecycle rules are very complex, this module supports only a subset of the rules. Since there can
  only be one set of Lifecycle Rules on a bucket, you have three options:
  1. Do not use this variable and accept the defaults.
  1. Use the attributes in this variable to configure the rules.
  2. Set the `enabled` attribute to false and provide your own rules using the
     aws_s3_bucket_lifecycle_configuration resource. Do this if your requirements are
     more complex than what is supported here.

  Attempting to use both the default rule and your own rule will result a perpetual difference in configuration.

  Further reading:
  * AWS Docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
  * Terraform Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration

  Note that lifecycle rules are only executed once per day. In addition S3 rounds transition or expiration dates
  up to midnight UTC the next day. So if you set a transition to intelligent tier to 1 day, it may take up
  to three days for the transition to complete. See https://repost.aws/knowledge-center/s3-lifecycle-rule-delay
  for a detailed explanation.

  This is a map of the following keys:
  * enabled - (Optional) Enable the rules, defaults to true. if you are providing your own rules set this to false
    and the remainder of the values will be ignored.
  * abort_incomplete_multipart_upload_days - (Optional) Number of days after which to abort
    incomplete multipart uploads. Defaults to 7. -1 means never. See the
    abort_incomplete_multipart_upload.days_after_initiation field in the life cycle configuration for details.
  * object_delete_days - (Optional) Number of days after which to delete objects. Valid values are -1 to disable,
    or greater than 0. See the expiration.days field in the life cycle configuration for details.
  * old_versions_delete_days - (Optional) Number of days after which to expire old versions of objects. Defaults to 30.
    -1 means never. See the noncurrent_version_expiration.days field in the life cycle configuration for details.
  * prefix - (Optional) The prefix to apply the lifecycle rule to. Defaults to "". An example is "logs/"
  * transition_to_intelligent_tier_days - (Optional) Number of days after which to transition objects
    to the Intelligent Tier storage class. Defaults to 1. -1 means never.
  EOF
  type = object({
    enabled                                = optional(bool, true)
    abort_incomplete_multipart_upload_days = optional(number, 7)
    object_delete_days                     = optional(number, -1)
    old_versions_delete_days               = optional(number, 30)
    prefix                                 = optional(string, "")
    transition_to_intelligent_tier_days    = optional(number, 1)
  })
  validation {
    condition     = var.lifecycle_rule.abort_incomplete_multipart_upload_days == -1 || var.lifecycle_rule.abort_incomplete_multipart_upload_days > 0
    error_message = "abort_incomplete_multipart_upload_days must be -1 to disable, or greater than 0."
  }
  validation {
    condition     = var.lifecycle_rule.object_delete_days == -1 || var.lifecycle_rule.object_delete_days > 0
    error_message = "object_delete_days must be -1 to disable, or greater than 0."
  }
  validation {
    condition     = var.lifecycle_rule.old_versions_delete_days == -1 || var.lifecycle_rule.old_versions_delete_days > 0
    error_message = "old_versions_delete_days must be -1 to disable, or greater than 0."
  }
  validation {
    condition     = var.lifecycle_rule.transition_to_intelligent_tier_days == -1 || var.lifecycle_rule.transition_to_intelligent_tier_days > 0
    error_message = "transition_to_intelligent_tier_days must be -1 to disable, or greater than 0."
  }
}

variable "cors_rules" {
  description = <<EOF
  The cors_rule configuration block supports the following arguments:

  allowed_headers - (Optional) Set of Headers that are specified in the Access-Control-Request-Headers header.
  allowed_methods - (Required) Set of HTTP methods that you allow the origin to execute. Valid values are GET, PUT, HEAD, POST, and DELETE.
  allowed_origins - (Required) Set of origins you want customers to be able to access the bucket from.
  expose_headers - (Optional) Set of headers in the response that you want customers to be able to access from their applications (for example, from a JavaScript XMLHttpRequest object).

  EOF

  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
  }))

  default = []

  validation {
    condition = alltrue([
      for rule in var.cors_rules : alltrue([
        for method in rule.allowed_methods : contains(["GET", "PUT", "HEAD", "POST", "DELETE"], method)
      ])
    ])
    error_message = "allowed_methods must be one of GET, PUT, HEAD, POST, or DELETE."
  }
}

variable "replication_destination_config" {
  description = <<EOF
  Object to configure the bucket as the destination of replication. All attributes are ignored if `enabled` is false.

  Attributes:
  * enabled - set to true if this is the destination bucket, else replication will not be enabled.
  * source_bucket_in_other_account - Set to true if the AWS Account ID of the source bucket is different from
    the destination bucket.
  * source_bucket_arn - The ARN of the source bucket.
  * source_service_role_arn - The ARN of the service role that will be used to replicate objects. Note that
    depending on how the role was created, it could be two different patterns:
    * arn:aws:iam::account-id:role/role-name - created with the CLI or via this module
    * arn:aws:iam::account-id:role/service-role/role-name - created with the Console
    See the output `replication_source_iam_role` for the IAM role created by this module on the source bucket.
  EOF
  type = object({
    enabled                        = bool
    source_bucket_in_other_account = bool
    source_bucket_arn              = string
    source_service_role_arn        = string
  })
  default = {
    enabled                        = false
    source_bucket_in_other_account = false
    source_bucket_arn              = ""
    source_service_role_arn        = ""
  }
}

variable "replication_source_config" {
  description = <<EOF
  Object to configure the bucket as the source of replication. All attributes are ignored if `enabled` is false.
  Attributes:
  * enabled - set to true if this is the source bucket, else replication will not be enabled.
  * destination_account_id - The AWS Account ID where the destination bucket is homed.
  * destination_bucket_arn - The ARN of the destination bucket.
  * destination_encryption_sse_algorithm - The encryption algorithm to use for encryption on the destination bucket.
    This must match what the destination bucket is configured for. Options are "SSE-S3", "SSE-KMS", or "DSSE-KMS". See
    the variable `encryption_sse_algorithm` for more information. Note that "SSE-S3" is not supported for cross-account
    replication.
  * destination_kms_key_arn - The ARN of the KMS key to use for server-side encryption in the destination bucket. This
    can be the Key or Alias ARN. If the encryption on the destination bucket is "SSE-KMS", and the destination bucket
    is in a different AWS account, aliases cannot be used, or the replication will fail. You MUST
    specify the KMS Key ARN, NOT an alias.
  * destination_region - The region of the destination bucket.
  * owner_translation - If true, ownership (AWS Account ID) of the object in the destination bucket will be set to the owner
    of the destination bucket. If false, the owner of the object written in the destination bucket will be that
    of the source bucket.
  * replication_prefix - The prefix to apply to the replication configuration, default is everything. Include wildcards
    if necessary. For example "Tax/" or "Tax*" are both legitimate.
  * replicate_delete_markers - Flag to indicate if delete markers should be replicated, which means objects
    deleted in the source bucket will also be deleted in the destination bucket.

  EOF
  type = object({
    enabled                              = bool
    destination_account_id               = string
    destination_bucket_arn               = string
    destination_encryption_sse_algorithm = string
    destination_kms_key_arn              = string
    destination_region                   = string
    owner_translation                    = bool
    replicate_delete_markers             = bool
    replication_prefix                   = string
  })
  default = {
    enabled                              = false
    destination_account_id               = ""
    destination_bucket_arn               = ""
    destination_encryption_sse_algorithm = ""
    destination_kms_key_arn              = ""
    destination_region                   = ""
    owner_translation                    = true
    replicate_delete_markers             = false
    replication_prefix                   = ""
  }
}

variable "account_id" {
  description = <<EOF
    The 12 digit AWS Account ID where the module is deployed, used in the name of the bucket.
    While ideally this module could use just the data source to lookup the Account ID, there are times
    when Terraform or OpenTofu will defer looking up the Account ID until the apply phase, and mark
    the bucket for replacement, which will result in data loss.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[0-9]+12$", var.account_id))
    error_message = "The account_id must be exactly 12 digits."
  }
}

variable "region" {
  description = <<EOF
    The AWS Region, like `us-east-2` where the module is deployed, used in the name of the bucket.
    While ideally this module could use just the data source to lookup the region, there are times
    when Terraform or OpenTofu will defer looking up the region until the apply phase, and mark
    the bucket for replacement, which will result in data loss.
  EOF
  type        = string
}