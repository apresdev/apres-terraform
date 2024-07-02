locals {
  s3_origin_id = "s3-${lower(var.name)}"
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = lower(var.name)
  description                       = "${title(var.name)} ${var.environment} Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "default" {
  name        = "${lower(var.name)}-${lower(var.environment)}-cache-policy"
  min_ttl     = 0
  max_ttl     = 3600
  default_ttl = 3600
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# It takes up to five minutes to create a distribution.
resource "aws_cloudfront_distribution" "default" {
  #checkov:skip=CKV2_AWS_47:Included WAF has log4j vulnerability mitigation
  #checkov:skip=CKV_AWS_310:TODO look at origin failover
  #checkov:skip=CKV2_AWS_32:TODO add response headers policy.
  comment = "${title(var.name)} ${var.environment} CloudFront Distribution"

  # Need the ACL to be in place before we can create the distribution
  depends_on = [aws_s3_bucket_acl.logging]

  origin {
    domain_name              = module.s3.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object

  logging_config {
    include_cookies = false
    bucket          = module.s3_logs.bucket_regional_domain_name
    prefix          = "${lower(var.name)}-${lower(var.environment)}-cloudfront-logs/"
  }

  default_cache_behavior {
    allowed_methods        = var.cloudfront_cache_allowed_methods
    cached_methods         = var.cloudfront_cache_cached_methods
    target_origin_id       = local.s3_origin_id
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.default.id
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geo_restrictions_type
      locations        = var.cloudfront_geo_restrictions_locations
    }
  }

  price_class = var.cloudfront_price_class

  web_acl_id = var.waf_arn == "" ? module.waf[0].waf_arn : var.waf_arn

  tags = merge(
    local.tags,
    tomap({
      Name = var.name
    })
  )

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn # if not set this statement is ignored

    # The following are required if ACM Certificate is set.
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    ssl_support_method             = "sni-only"
    # TODO: The docs say this can oly be set if cloudfront_default_certificate=false, but
    # we don't really have a way to test it at this point, so we hard code it.
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = var.aliases
}

