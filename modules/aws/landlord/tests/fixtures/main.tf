module "landlord" {
  source = "../../"

  name        = var.name
  environment = var.environment
  application = "Landlord"
  component   = "Auth"
  owner       = "Engineering"

  app_name        = "Unittest"
  app_url         = "https://nonexistent.${var.domain}"
  app_admin_email = "noreply@${var.domain}"
  sms_aws_region  = "us-west-2"

  hosted_zone_name     = var.domain
  custom_domain_prefix = "csh-test"

  vpc_environment_tag = var.vpc_environment_tag
}
