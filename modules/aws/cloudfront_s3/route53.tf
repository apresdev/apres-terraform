locals {
  do_route53        = var.hosted_zone_name != ""
  do_primary_domain = local.do_route53 && var.primary_domain != ""
  do_alias_domains  = local.do_route53 && length(var.alias_domains) > 0
  alias_domains     = local.do_alias_domains ? var.alias_domains : []
}

# This is an Alias record for Cloudfront, needs to be an A record even though it feels like
# it should be a CNAME. See
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-alias.html
resource "aws_route53_record" "primary" {
  #checkov:skip=CKV2_AWS_23:Attaching a resource to an A record is on purpose for a CloudFront distribution
  count   = local.do_primary_domain ? 1 : 0
  zone_id = data.aws_route53_zone.default[0].zone_id
  name    = var.primary_domain
  type    = "A"
  alias {
    name                   = resource.aws_cloudfront_distribution.default.domain_name
    zone_id                = resource.aws_cloudfront_distribution.default.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aliases" {
  #checkov:skip=CKV2_AWS_23:Attaching a resource to an A record is on purpose for a CloudFront distribution
  for_each = toset(var.alias_domains)
  zone_id  = data.aws_route53_zone.default[0].zone_id
  name     = each.key
  type     = "A"
  alias {
    name                   = resource.aws_cloudfront_distribution.default.domain_name
    zone_id                = resource.aws_cloudfront_distribution.default.hosted_zone_id
    evaluate_target_health = true
  }
}