module "landlord_waf" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source                 = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/waf?ref=rel/waf/1.1.2"
  associate_resource_arn = module.landlord_api_gateway.apigw_stage_arn
  application            = var.application
  component              = var.component
  environment            = var.environment
  name                   = var.name
  scope                  = "REGIONAL"
  depends_on = [
    module.landlord_api_gateway
  ]
}