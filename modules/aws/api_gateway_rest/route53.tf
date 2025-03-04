resource "aws_route53_record" "apigw_alias" {
  #checkov:skip=CKV2_AWS_23:Attaching a resource to an A record is on purpose for an API Gateway domain
  count   = local.do_route53 ? 1 : 0
  zone_id = data.aws_route53_zone.default.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.default[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.default[0].regional_zone_id
    evaluate_target_health = true
  }
}

