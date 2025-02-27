module "acm_public_cert_console" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/acm_public_cert?ref=rel/acm_public_cert/2.0.0"
  application = var.application
  environment = var.environment
  component   = var.component
  domain_name = local.console_domain_name
  hosted_zone = var.hosted_zone_name
}

module "acm_public_cert_api" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/acm_public_cert?ref=rel/acm_public_cert/2.0.0"
  application = var.application
  environment = var.environment
  component   = var.component
  domain_name = local.api_domain_name
  hosted_zone = var.hosted_zone_name
}