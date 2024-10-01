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
  that include ARN's of other resources. If that's the case, set this to false, and then use the output `default_bucket_policy`
  to include in your own policy. For example, in your code:
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
    The statement SID's must be uniuqe, the SID used in the default policy is "DenyUnSecureCommunications".
  EOF
  type        = bool
  default     = true
}

variable "encryption_sse_algorithm" {
  description = "The server-side encryption algorithm to use. Defaults to 'aws:kms'."
  type        = string
  default     = "aws:kms"
}

variable "encryption_kms_key_id" {
  description = <<EOF
  The ARN of the KMS key to use for server-side encryption. If not provided,
  the default AWS managed key 'aws/s3' will be used.
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
  only be one set of Lifecycle Rules on a bucket, you have two options:
  1. Set the `enabled` flag to true (the default) and use the values here to configure the rules.
  2. Set the `enabled` flag to false and provide your own rules using the aws_s3_bucket_lifecycle_configuration
     resource. Do this if your requirements are more complex than what is supported here.

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