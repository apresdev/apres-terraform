# TODO: Ideally we want Alias records for these, but to do that we need to expose the LB Zone ID
# from the ECS module, which we don't (yet). So for now they are CNAME's.
# Or even better, create the Route53 entries in the ECS module?
resource "aws_route53_record" "console" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = local.console_domain_name
  type    = "CNAME"
  ttl     = "60"
  records = [module.landlord_console_ecs.load_balancer_dns_name]
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = local.api_domain_name
  type    = "CNAME"
  ttl     = "60"
  records = [module.landlord_api_ecs.load_balancer_dns_name]
}