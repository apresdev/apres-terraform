# This metric is emitted by the ecs_events terraform module.
module "cloudwatch_alarm" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.2.1"
  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${var.name}-TaskCrashLoop"
  environment = var.environment
  application = var.application
  component   = "ECSEventsLambda"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/ecs_events/README.md"
  description         = "An ECS task is in a crash loop, restarting frequently."
  evaluation_periods  = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "Apres/ECS"
  dimensions = {
    Cluster = local.name
    Service = local.name
    Task    = local.name
  }
  statistic   = "Sum"
  metric_name = "TaskNonZeroExitCode"
  threshold   = var.crash_loop_threshold
}