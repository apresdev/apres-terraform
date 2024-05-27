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