module "cloudwatchlogs_regional" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source                     = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs_regional?ref=rel/cloudwatchlogs_regional/1.2.1"
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
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/lambda_regional?ref=rel/lambda_regional/0.3.2"
  environment = "WorkloadConfig"
}

module "ecs_events" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/ecs_events?ref=rel/ecs_events/0.4.0"
  name        = "ECSEvents"
  environment = "WorkloadConfig"
  application = "ECSEvents"
  component   = "ECSEvents"

  # Need to pass this in or else we get a race condition with lookups and creations on new accounts
  code_signing_name_ssm_parameter = module.lambda_regional.signing_config_name_ssm_parameter
  code_signing_arn_ssm_parameter  = module.lambda_regional.signing_config_arn_ssm_parameter

  # Need this to handel the race condition with the ssm parameters that don't exist yet on
  # new accounts.
  depends_on = [
    module.lambda_regional
  ]
}

resource "aws_ebs_encryption_by_default" "default" {
  enabled = true
}