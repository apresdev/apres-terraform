module "cloudwatchlogs_regional" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source                     = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs_regional?ref=rel/cloudwatchlogs_regional/1.2.0"
  environment                = "WorkloadConfig"
  enable_api_gateway_logging = var.enable_api_gateway_logging
}