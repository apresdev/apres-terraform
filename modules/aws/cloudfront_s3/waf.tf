module "waf" {
  count = var.waf_arn == "" ? 1 : 0
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/waf?ref=rel/waf/1.1.2"
  name        = var.name
  environment = var.environment
  application = var.application
  component   = "WAF"
  owner       = var.owner
  # WAF's for CloudFront must be created in us-east-1
  providers = {
    aws = aws.us-east-1
  }
  scope              = "CLOUDFRONT"
  associate_resource = false
}