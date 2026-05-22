module "cwl_apigateway" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.2.2"
  name        = "${var.name}-apigateway"
  environment = var.environment
  application = var.application
  component   = "CloudWatchLogs"
  path        = "/${var.application}-${var.component}/${var.environment}-${var.name}-apigateway"
}
