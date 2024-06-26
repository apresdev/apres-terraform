module "waf" {
  count       = var.waf_arn == "" ? 1 : 0
  source      = "./modules/waf"
  environment = var.environment
  name        = var.name
  application = var.application
  owner       = var.owner
  # WAF's for CloudFront must be created in us-east-1
  providers = {
    aws = aws.us-east-1
  }
}