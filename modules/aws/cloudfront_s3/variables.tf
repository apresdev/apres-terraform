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
  EOF
  type        = string
  default     = ""
}

variable "aliases" {
  description = <<EOF
    List of aliases to apply to the CloudFront distribution. The first alias in the list will be
    the primary domain name for the distribution.
  EOF
  type        = list(string)
  default     = []
}
