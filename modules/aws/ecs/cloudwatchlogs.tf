module "cloudwatchlogs" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.0.0"
  name        = var.name # case sensitive, leave as is.
  environment = var.environment
  application = var.application
  component   = "CloudWatchLogs"
  path        = local.cwl_log_group_name
}
