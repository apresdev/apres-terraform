module "cloudwatchlogs_regional" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source                     = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs_regional?ref=rel/cloudwatchlogs_regional/1.2.0"
  environment                = "WorkloadConfig"
  enable_api_gateway_logging = var.enable_api_gateway_logging
}

module "messaging_regional" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/messaging_regional?ref=rel/messaging_regional/0.1.0"
  environment = "WorkloadConfig"
}

module "lambda_regional" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/lambda_regional?ref=rel/lambda_regional/0.2.4"
  environment = "WorkloadConfig"
}

module "ecs_events" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/ecs_events?ref=rel/ecs_events/0.2.0"
  name        = "ECSEvents"
  environment = "WorkloadConfig"
  application = "ECSEvents"
  component   = "ECSEvents"
}