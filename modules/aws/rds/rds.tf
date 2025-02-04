locals {
  cwl_types = var.engine == "aurora-postgresql" ? ["postgresql"] : ["audit", "error", "general", "slowquery"]
}


# Create cluster and instance parameter groups. Changing parameter groups
# can be disruptive so we'll create them even if keeping the defaults, it
# makes tuning easier later.
resource "aws_rds_cluster_parameter_group" "default" {
  name        = "${local.name}-cluster"
  description = "Parameter group for ${local.name} cluster"
  family      = var.db_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  tags = merge(
    local.tags,
    {
      "Name" = "${local.name}-cluster"
    }
  )
}

resource "aws_db_parameter_group" "default" {
  name        = "${local.name}-instance"
  family      = var.db_parameter_group_family
  description = "Parameter group for ${local.name} instance"

  dynamic "parameter" {
    for_each = var.db_instance_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.name}-instance"
    }
  )
}

resource "aws_rds_cluster" "default" {
  #checkov:skip=CKV_AWS_226:False positive, minor version updates are allowed and the parameter does not exist for Aurora.
  #checkov:skip=CKV_AWS_118:False positive, enhanced monitoring is not configured at the Aurora cluster level.
  #checkov:skip=CKV2_AWS_8:Aurora has point-in-time backups, not enabling AWS Backup.
  #checkov:skip=CKV_AWS_139:False positive, deletion protection is managed with the `is_production` variable.
  #checkov:skip=CKV2_AWS_27:Query logging only applies to PostgreSQL, a prescriptive setting does not make sense.

  # set the cluster id, which how the cluster is referenced in AWS. The database_name is the internal PosgreSQL db
  # that the users connect to.
  cluster_identifier = local.name
  database_name      = var.database_name

  lifecycle {
    precondition {
      # If is_production and number instances < 2, fail. If not production we don't care.
      condition     = var.is_production ? (var.number_cluster_instances >= 2 ? true : false) : true
      error_message = "Production clusters must have at least 2 instances, set `number_cluster_instances` to at least 2."
    }
  }

  # DB type and version
  engine         = var.engine
  engine_version = var.engine_version

  # the 'serverless' option is only for serverless v1, provisioned is the default for serverless v2 or
  # non-serverless clusters.
  engine_mode = "provisioned"

  # serverless configuration - only one dynamic block allowed, and it depends
  # on the `serverless` variable. Ignore seconds_until_auto_pause if min_capacity != 0
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverless == true ? [var.serverless_scaling] : []
    content {
      max_capacity             = var.serverless_scaling.max_capacity
      min_capacity             = var.serverless_scaling.min_capacity
      seconds_until_auto_pause = var.serverless_scaling.min_capacity == 0 ? var.serverless_scaling.seconds_until_auto_pause : null
    }
  }

  # Config
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name

  # Authentication
  master_username                     = var.master_username
  master_password                     = random_password.master_password.result
  iam_database_authentication_enabled = true

  # Storage encryption and type. Standard storage is represented with an empty string.
  kms_key_id        = aws_kms_key.default.arn
  storage_encrypted = true
  storage_type      = var.storage_type == "standard" ? "" : "aurora-iopt1"

  # Networking and AZ's
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Production protections
  deletion_protection       = var.is_production
  delete_automated_backups  = var.is_production ? false : true
  skip_final_snapshot       = var.is_production ? false : true
  final_snapshot_identifier = var.is_production ? "${local.name}-final" : null

  # Backups and Maintenance. Backtrack is only supported for MySQL
  allow_major_version_upgrade  = var.allow_major_version_upgrades
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  backup_retention_period      = var.backup_retention_period
  backtrack_window             = var.engine == "aurora-mysql" ? var.backtrack_window : null

  # Monitoring & Logging
  enabled_cloudwatch_logs_exports       = local.cwl_types
  performance_insights_enabled          = var.performance_insights_retention > 0 ? true : false
  performance_insights_kms_key_id       = var.performance_insights_retention == 0 ? null : aws_kms_key.default.arn
  performance_insights_retention_period = var.performance_insights_retention == 0 ? null : var.performance_insights_retention

  # Tags
  copy_tags_to_snapshot = true
  tags = merge(
    local.tags,
    {
      "Name" = local.name
    }
  )

  # we shouldn't in theory need this but sometimes the deletes are out of order, so
  # we'll try to make sure the parameter group is deleted last.
  depends_on = [aws_rds_cluster_parameter_group.default]
}

resource "aws_rds_cluster_instance" "default" {
  #checkov:skip=CKV_AWS_118:Enhanced monitoring is configurable, not defaulted to true.
  count = var.number_cluster_instances

  cluster_identifier = aws_rds_cluster.default.id
  identifier         = "${local.name}-${count.index}"

  # DB type and size
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.serverless ? "db.serverless" : var.instance_class

  # config
  db_parameter_group_name = aws_db_parameter_group.default.name

  # handling upgrades
  apply_immediately          = var.is_production ? false : true
  auto_minor_version_upgrade = true

  # Networking - must be same as the cluster
  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = false # Defaults to false but let's be sure.

  # Monitoring
  monitoring_interval                   = var.enhanced_os_monitoring
  monitoring_role_arn                   = var.enhanced_os_monitoring == 0 ? null : aws_iam_role.rds_monitoring.arn
  performance_insights_enabled          = var.performance_insights_retention > 0 ? true : false
  performance_insights_kms_key_id       = var.performance_insights_retention == 0 ? null : aws_kms_key.default.arn
  performance_insights_retention_period = var.performance_insights_retention == 0 ? null : var.performance_insights_retention

  # Tags
  copy_tags_to_snapshot = true
  tags = merge(
    local.tags,
    {
      "Name" = local.name
    }
  )

  depends_on = [aws_db_parameter_group.default]
}

