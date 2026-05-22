module "cloudwatch_log" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.2.3"

  name              = local.name
  path              = local.log_group
  retention_in_days = 365
  region            = local.region

  environment = var.environment
  component   = var.component
  application = var.application
  owner       = var.owner
}
