variable "name" {
  description = "Name of the distribution, used to create resources including the S3 bucket"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens, spaces and underscores."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
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
  default     = "CloudFrontS3"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "environment" {
  description = "Environment Name, used for naming and tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}

variable "default_root_object" {
  description = <<EOF
  Default root file to serve. See
  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DefaultRootObject.html
  EOF
  type        = string
  default     = "index.html"
}

variable "is_spa" {
  description = <<EOF
  Whether the site is a Single Page Application and 403, 404 error messages should be re-directed to the root object
  EOF
  type        = bool
  default     = false
}

variable "cloudfront_custom_error_responses" {
  description = <<EOF
  Custom error responses. See
  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GeneratingCustomErrorResponses.html
  EOF
  type        = list(any)
  default     = []
}

variable "cloudfront_custom_spa_error_responses" {
  description = <<EOF
  Custom error responses for SPA applications. See
  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GeneratingCustomErrorResponses.html
  EOF
  type        = list(any)
  default     = []
}

variable "cloudfront_logs_transition_ia" {
  description = "Number of days before logs are transitioned to IA storage class."
  type        = number
  default     = 30
}

variable "cloudfront_logs_transition_glacier" {
  description = "Number of days before logs are transitioned to Glacier storage class."
  type        = number
  default     = 90
}

variable "cloudfront_logs_expiration" {
  description = "Number of days before logs are deleted."
  type        = number
  default     = 365
}

variable "cloudfront_geo_restrictions_type" {
  description = "Type of geo restrictions to apply to the CloudFront distribution, one of 'none', 'blacklist', or 'whitelist'."
  type        = string
  default     = "none"
  validation {
    condition     = var.cloudfront_geo_restrictions_type == "none" || var.cloudfront_geo_restrictions_type == "blacklist" || var.cloudfront_geo_restrictions_type == "whitelist"
    error_message = "cloudfront_geo_restrictions_type must be one of 'none', 'blacklist', or 'whitelist'"
  }
}

variable "cloudfront_geo_restrictions_locations" {
  description = <<EOF
  List of locations to apply to the CloudFront distribution, in form of ISO-3166 Country Codes, see
  http://www.iso.org/iso/country_codes/iso_3166_code_lists/country_names_and_code_elements.html for a list.
  Only valid if cloudfront_geo_restrictions_type is 'blacklist' or 'whitelist'.

  Example: ["US", "CA"]
  EOF
  type        = list(string)
  default     = []
}

variable "cloudfront_cache_allowed_methods" {
  description = <<EOF
  List of allowed HTTP methods for the CloudFront cache policy. Must be one of:
  * ["HEAD", "GET"] or
  * ["HEAD", "GET", "OPTIONS"] or
  * ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
  EOF
  type        = list(string)
  default     = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
}

variable "cloudfront_cache_cached_methods" {
  description = "List of cached HTTP methods for the CloudFront cache policy."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cloudfront_price_class" {
  description = <<EOF
  Price class for the CloudFront distribution. See
  https://aws.amazon.com/cloudfront/pricing/ for details
  EOF
  type        = string
  default     = "PriceClass_200"
}

variable "waf_arn" {
  description = <<EOF
    ARN of the WAF to attach to the CloudFront distribution. The provided ARN must be of a WAF v2
    with scope "CLOUDFRONT" deployed in us-east-1.

    If not set, a default WAF with the following rulesets will be created:
    * AWSManagedRulesCommonRuleSet
    * AWSManagedRulesKnownBadInputsRuleSet
    * AWSManagedRulesAnonymousIpList
  EOF
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = <<EOF
    The ARN of an ACM SSL Certificate to use with the distribution. If not set, the default
    CloudFront certificate will be used. Note the ACM Certificate must be in us-east-1!

    There are several reasons to create a certificate outside this module:
    1. The cloudfront module is not deployed to us-east-1 - in that case you must create the certificate
       in us-east-1 and pass in ARN here.
    2. One or more of the entries in `alias_domains` is not in the domain specified by the `hosted_zone_name`,
       which means that automatic creation of the Route53 DNS records required for domain validation cannot be
       created - in that case you must create the certificate in us-east-1, manage the DNS records manually, and
       pass in the ARN here.
  EOF
  type        = string
  default     = ""
}

variable "hosted_zone_name" {
  description = <<EOF
    The name of the hosted zone in Route53 in which to create the
    alias records for the CloudFront distribution. If not specified, creation of Route53 aliases using
    the primary_domain and alias_domains will be skipped.
  EOF
  type        = string
  default     = ""
}

variable "primary_domain" {
  description = <<EOF
    The primary domain name for the CloudFront distribution. A Route53 alias will be created using this domain.
    This name will be the first alias in the aliases list.

    Note: This domain must be the domain name or in the subject_alternative_name list of the ACM certificate.
  EOF
  type        = string
  default     = ""
}

variable "alias_domains" {
  description = <<EOF
    List of aliases to apply to the CloudFront distribution. Note that if an entry does not
    end with the `hosted_zone_name`, no alias record will be created in Route53, since this
    module will not know where the domain is hosted.

    For example, if:
    * hosted_zone_name = "example.com"
    * primary_domain = "something.example.com"
    * alias_domains = ["www.example.com", "somethingelse.com"]
    Then:
    * The alias record for `something.example.com` and `www.example.com` will be created in Route53
      in the `example.com` domain, but not for `somethingelse.com`.

    Note: All alias domains should be in the subject_alternative_name list of the ACM certificate.
  EOF
  type        = list(string)
  default     = []
}

variable "allow_browser_uploads" {
  description = <<EOF
    Enables the CORS rules in the S3 bucket to allow pre-signed PutObject requests from the browser.
  EOF
  type        = bool
  default     = false
}

variable "replication_destination_config" {
  description = <<EOF
  Object to configure the S3 bucket as the destination of replication. All attributes are ignored if `enabled` is false.

  Attributes:
  * enabled - set to true if this is the destination bucket, else replication will not be enabled.
  * source_bucket_account - The AWS Account ID where the source bucket is homed.
  * source_bucket_arn - The ARN of the source bucket.
  * source_service_role_arn - The ARN of the service role that will be used to replicate objects. Note that
    depending on how the role was created, it could be two different patterns:
    * arn:aws:iam::account-id:role/role-name - created with the CLI or via this module
    * arn:aws:iam::account-id:role/service-role/role-name - created with the Console
    See the output `replication_source_iam_role` for the IAM role created by this module on the source bucket.
  EOF
  type = object({
    enabled                 = bool
    source_bucket_account   = string
    source_bucket_arn       = string
    source_service_role_arn = string
  })
  default = {
    enabled                 = false
    source_bucket_account   = ""
    source_bucket_arn       = ""
    source_service_role_arn = ""
  }
}

variable "replication_source_config" {
  description = <<EOF
  Object to configure the S3 bucket as the source of replication. All attributes are ignored if `enabled` is false.
  Attributes:
  * enabled - set to true if this is the source bucket, else replication will not be enabled.
  * destination_account_id - The AWS Account ID where the destination bucket is homed.
  * destination_bucket_arn - The ARN of the destination bucket.
  * destination_kms_key_arn - The ARN of the KMS key to use for server-side encryption in the destination bucket.
    This _may_ be the KMS Alias if the source and bucket are in the same account.
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
    enabled                  = bool
    destination_account_id   = string
    destination_bucket_arn   = string
    destination_kms_key_arn  = string
    destination_region       = string
    owner_translation        = bool
    replicate_delete_markers = bool
    replication_prefix       = string
  })
  default = {
    enabled                  = false
    destination_account_id   = ""
    destination_bucket_arn   = ""
    destination_kms_key_arn  = ""
    destination_region       = ""
    owner_translation        = true
    replicate_delete_markers = false
    replication_prefix       = ""
  }
}