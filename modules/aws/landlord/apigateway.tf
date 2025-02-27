module "landlord_api_gateway" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source                 = "git@github.com:apresdev/apres-terraform.git//modules/aws/api_gateway_rest?ref=rel/api_gateway_rest/1.1.0"
  api_version            = "v1"
  openapi_spec_file_path = "${path.module}/api/landlord-openapi-ext.json"
  application            = var.application
  component              = var.component
  environment            = var.environment
  name                   = var.name
  openapi_spec_variables = {
    nlb_uri              = "http://${module.landlord_api_ecs.load_balancer_dns_name}"
    cognito_provider_arn = aws_cognito_user_pool.default.arn
  }
  load_balancer_arn        = module.landlord_api_ecs.load_balancer_arn
  attach_vpc_load_balancer = true
}