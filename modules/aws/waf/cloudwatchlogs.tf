
module "cwl_waf" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.2.2"
  name        = "${var.name}-waf"
  environment = var.environment
  application = var.application
  component   = "CloudWatchLogs"
  # WAF demands the default path to start with "aws-waf-logs-" as per
  # https://docs.aws.amazon.com/waf/latest/developerguide/logging-cw-logs.html#logging-cw-logs-naming
  path = "aws-waf-logs-${var.application}-${var.component}/${var.name}-${var.environment}"
}