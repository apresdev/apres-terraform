module "cwl_apigateway" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.0.0"
  name        = "${var.name}-${var.environment}-apigateway"
  environment = var.environment
  application = var.application
  component   = "CloudWatchLogs"
  path        = "/${var.application}-${var.component}/${var.name}-${var.environment}-apigateway"
}
