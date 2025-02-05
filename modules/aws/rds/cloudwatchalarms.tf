# Annoyingly, the URL's for the runbook are set as tags, and can't include the "#" symbol so we
# can't link to the specific section.

# This metric is emitted by the ecs_events terraform module.
module "cwa_cpu_utilization" {
  count = var.create_cloudwatch_alarms ? var.number_cluster_instances : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.1.0"

  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${local.name}-CPUUtilization-${count.index}"
  environment = var.environment
  application = var.application
  component   = "RDS"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/rds/ALARMS_RUNBOOK.md"
  description         = "CPU Utilization is too high on the instance"
  evaluation_periods  = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.default[count.index].id
  }
  statistic   = "Average"
  metric_name = "CPUUtilization"
  threshold   = var.alarm_thresholds["cpu_utilization"]
}

module "cwa_acu_utilization" {
  count = var.create_cloudwatch_alarms && var.serverless ? var.number_cluster_instances : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.1.0"

  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${local.name}-ACUUtilization-${count.index}"
  environment = var.environment
  application = var.application
  component   = "RDS"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/rds/ALARMS_RUNBOOK.md"
  description         = "ACU Utilization is too high on the instance"
  evaluation_periods  = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.default[count.index].id
  }
  statistic   = "Average"
  metric_name = "CPUUtilization"
  threshold   = var.alarm_thresholds["acu_utilization"]
}

module "cwa_freeable_memory" {
  count = var.create_cloudwatch_alarms ? var.number_cluster_instances : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.1.0"

  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${local.name}-FreeableMemory-${count.index}"
  environment = var.environment
  application = var.application
  component   = "RDS"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/rds/ALARMS_RUNBOOK.md"
  description         = "Freeable Memory is too low on the instance"
  evaluation_periods  = 5
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.default[count.index].id
  }
  statistic   = "Average"
  metric_name = "FreeableMemory"
  threshold   = var.alarm_thresholds["free_memory"] * 1024 * 1024 * 1024
}

module "cwa_read_latency" {
  count = var.create_cloudwatch_alarms ? var.number_cluster_instances : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.1.0"

  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${local.name}-ReadLatency-${count.index}"
  environment = var.environment
  application = var.application
  component   = "RDS"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/rds/ALARMS_RUNBOOK.md"
  description         = "Read Latency is too high on the instance"
  evaluation_periods  = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.default[count.index].id
  }
  statistic   = "Average"
  metric_name = "ReadLatency"
  threshold   = var.alarm_thresholds["read_latency"]
}

module "cwa_write_latency" {
  count = var.create_cloudwatch_alarms ? var.number_cluster_instances : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.1.0"

  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${local.name}-WriteLatency-${count.index}"
  environment = var.environment
  application = var.application
  component   = "RDS"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/rds/ALARMS_RUNBOOK.md"
  description         = "Write Latency is too high on the instance"
  evaluation_periods  = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.default[count.index].id
  }
  statistic   = "Average"
  metric_name = "WriteLatency"
  threshold   = var.alarm_thresholds["write_latency"]
}

module "cwa_buffer_cache_hit_ratio" {
  count = var.create_cloudwatch_alarms ? 1 : 0
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatch_alarm?ref=rel/cloudwatch_alarm/0.1.0"

  # the generated alarm name will become ${var.enviroment}-${var.name}-${var.severity}
  name        = "${local.name}-BufferCacheHitRatio"
  environment = var.environment
  application = var.application
  component   = "RDS"
  owner       = var.owner

  severity            = "SEV1"
  runbook             = "https://github.com/apresdev/apres-terraform/blob/main/modules/aws/rds/ALARMS_RUNBOOK.md"
  description         = "Buffer Cache Hit Ratio is too low on the cluster"
  evaluation_periods  = 5
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # missing data is fine, means no exits

  namespace = "AWS/RDS"
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default.id
  }
  statistic   = "Average"
  metric_name = "BufferCacheHitRatio"
  threshold   = var.alarm_thresholds["buffer_cache_hit_ratio"]
}