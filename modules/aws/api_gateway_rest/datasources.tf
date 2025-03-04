data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_route53_zone" "default" {
  count = local.do_route53 ? 1 : 0
  name  = var.hosted_zone_name
}