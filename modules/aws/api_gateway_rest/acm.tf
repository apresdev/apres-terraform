module "acm_certificate" {
  count = local.do_route53 && var.acm_certificate_arn == "" ? 1 : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/acm_public_cert?ref=rel/acm_public_cert/2.0.0"
  domain_name = var.domain_name
  hosted_zone = var.hosted_zone_name

  application = var.application
  component   = var.component
  environment = var.environment
}