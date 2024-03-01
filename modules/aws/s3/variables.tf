variable "environment" {
  description = "Environment name, used for tagging AWS resources."
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
  description = "Flag to indicate if MFA delete is enabled.  Defaults to true due to best practice: Ensure S3 bucket MFA Delete is enabled."
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
