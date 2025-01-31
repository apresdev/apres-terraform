variable "name" {
  description = "Name used to create resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "environment" {
  description = "Environment name, used for naming and tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}

variable "vpc_environment_tag" {
  description = <<EOF
    The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC
    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more
    if it was configured that way.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.vpc_environment_tag))
    error_message = "VPC Environment Tag must be alphanumeric and capitalized."
  }
}

variable "database_name" {
  description = <<EOF
    Name of the database to create inside the DB cluster. This will be used by your
    application. Database names must be lower case, and can contain numbers or underscores, with a maximum
    of 63 letters.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9_]{1,63}$", var.database_name))
    error_message = "Database name must be lower case, alphanumeric, and can contain underscores, and not be longer than 63 characters."
  }
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.master_username))
    error_message = "Username must be alphanumeric."
  }
}

variable "number_cluster_instances" {
  description = <<EOF
    Number of instances in the cluster. Must be >= 2 if `is_production` is true.

    The first instance created will be the writer instance, and it can be accessed using the cluster endpoint. The
    remainder of the instances will be read replicas, and can be accessed using the instance-specific endpoints.
  EOF
  type        = number
  default     = 2
  validation {
    condition     = var.number_cluster_instances > 0 && var.number_cluster_instances <= 15
    error_message = "Number of instances must be greater than zero and less than or equal to 15."
  }
}

variable "engine" {
  description = "One of the supported database engines, 'aurora-postgresql' or 'aurora-mysql'"
  type        = string
  validation {
    condition     = can(regex("^(aurora-mysql|aurora-postgresql)$", var.engine))
    error_message = "Engine must be one of 'aurora-mysql' or 'aurora-postgresql'."
  }
}

variable "engine_version" {
  description = <<EOF
    Version of the database engine to use. There is no default, since it depends on the `engine` variable,
    which is one of 'aurora-postgresql' or 'aurora-mysql'.

    The definitive way to find a list of version is to use the AWS CLI:
    `aws rds describe-db-engine-versions --engine aurora-postgresql --query 'DBEngineVersions[].EngineVersion'`
    or
    `aws rds describe-db-engine-versions --engine aurora-mysql --query 'DBEngineVersions[].EngineVersion'`

    Apres recommends using the latest version available, to extend the amount of time before you need
    to upgrade. At January 2025 that is:
    * aurora-postgresql: 16.6
    * aurora-mysql: 3.08.0
  EOF
  type        = string
}

variable "db_parameter_group_family" {
  description = <<EOF
    The name of the DB parameter group family to use. This is specific to the engine and version
    of the database, and can't be calculated.

    Typical family groups are:
    * aurora-postgresql16
    * aurora-mysql8.0

    The definitive way to find a list of parameter group families is to use the AWS CLI:
    `aws rds describe-db-engine-versions --engine aurora-postgresql --query 'DBEngineVersions[].DBParameterGroupFamily'`
    or
    `aws rds describe-db-engine-versions --engine aurora-mysql --query 'DBEngineVersions[].DBParameterGroupFamily'`

    See the README for more discussion on version and examples.
  EOF
  type        = string
}

variable "db_cluster_parameters" {
  description = <<EOF
    A list of parameters you can customize on a DB cluster. If left empty, the default
    parameters will be used, any values set here override the default.

    See the following docs for the parameters and the defaults:
    * [Aurora PosgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html)
    * [Aurora MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.ParameterGroups.html)
  EOF
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "db_instance_parameters" {
  description = <<EOF
    A list of parameters you can customize on a DB instance. If left empty, the default
    parameters will be used, any values set here overridex the default.

    See the following docs for the parameters and the defaults:
    * [Aurora PosgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html#AuroraPostgreSQL.Reference.Parameters.Instance)
    * [Aurora MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.ParameterGroups.html#AuroraMySQL.Reference.Parameters.Instance)
  EOF
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "allow_major_version_upgrades" {
  description = <<EOF
    Determines if major version upgrades are allowed. If set to true, the database
    will be upgraded to the latest major version when it is available, in the next maintenance
    window. If set to false, which is what you typically want in a production environment,
    the database will not be upgraded.

    See the README for further discussion.
  EOF
  type        = bool
  default     = false
}

variable "instance_class" {
  description = <<EOF
    Instance class to use for the database. See the README for details.

    If the `serverless` variable is set, this variable is ignored.
  EOF
  type        = string
  validation {
    condition     = can(regex("^db.", var.instance_class))
    error_message = "Instance class begin with `db.`"
  }
}

variable "serverless" {
  description = <<EOF
    If set to true, the database will be a serverless (v2) database. The `instance_class`
    variable will be ignored.
  EOF
  type        = bool
  default     = false
}

variable "serverless_scaling" {
  description = <<EOF
    Serverless scaling configuration, ignored if `serverless` is false.

    Auto-pause is only enabled if `min_capacity` is set to zero.

    See [Aurora Serverless v2 scaling](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html#aurora-serverless-v2.how-it-works.capacity)
    for details on the capacity parameters.
  EOF
  type = object({
    max_capacity             = number
    min_capacity             = number
    seconds_until_auto_pause = number
  })
  default = {
    max_capacity             = 2
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
  validation {
    condition     = var.serverless_scaling.seconds_until_auto_pause >= 300 && var.serverless_scaling.seconds_until_auto_pause < 86400
    error_message = "Seconds until auto pause must be between 300 and 86400."
  }
  validation {
    condition     = var.serverless_scaling.max_capacity > 0 && var.serverless_scaling.max_capacity <= 256
    error_message = "Max capacity must be between 0 and 256."
  }
  validation {
    condition     = var.serverless_scaling.min_capacity >= 0 && var.serverless_scaling.min_capacity <= 256
    error_message = "Max capacity must be between 0 and 256."
  }
  validation {
    condition     = var.serverless_scaling.max_capacity >= var.serverless_scaling.min_capacity
    error_message = "Max capacity must be greater than or equal to min capacity."
  }
}

variable "backup_retention_period" {
  description = "Number of days to retain backups for."
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period > 0
    error_message = "Backup retention period must be greater than zero."
  }
}

variable "backup_window" {
  description = <<EOF
    Time range in UTC during which automated backups are created. For example,
    04:00-04:30. Must not overlap with maintenance window. The default 06:00-06:30 UTC
    is 01:00-01:30 EST.
  EOF
  type        = string
  default     = "06:00-06:30"
  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in the format HH:MM-HH:MM."
  }
}

variable "maintenance_window" {
  description = <<EOF
    Day and time range in UTC during which maintenance is performed. For example, Sun:05:00-Sun:05:30.
    Must not overlap with `backup_window`. The default of Sun:07:00-Sun:07:30 UTC is 02:00-02:30 EST on
    Sunday.
  EOF
  type        = string
  default     = "Sun:07:00-Sun:07:30"
  validation {
    condition     = can(regex("^[a-zA-Z]{3}:[0-2][0-9]:[0-5][0-9]-[a-zA-Z]{3}:[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "Maintenance window must be in the format DayHH:MM-DayHH:MM."
  }
}

variable "is_production" {
  description = <<EOF
    Indicates if the database is a production database. This will be used to determine
    two parameters - deletion protection of the instance, and deleting automated backups.

    If set to false:
    * Deletion protection will be disabled
    * Automated backups will be deleted when the instance is deleted
    * No final snapshot will be taken when the instance is deleted
    * Disruptive changes will be applied immediately instead of in the next maintenance window

    If set to true:
    * Deletion protection will be enabled, the instance won't be able to be deleted without
      a manual step to disable it
    * Automated backups will be retained should the instance be deleted.
    * A final snapshot of the DB will be taken on deletion, named the same as the instance name with
      "-final" appended.
    * Any disruptive changes will be applied in the next maintenance window.
    * Plan and Apply will fail if `number_cluster_instances` < 2
  EOF
  type        = bool
  default     = true
}

variable "allow_ingress_from_all_private_subnets" {
  description = <<EOF
    If set to true, the security group will allow incoming connections from all private subnets
    in the VPC. This is NOT recommended, as it opens up the database to all services running in the VPC.

    Apres recommends setting this to false, and either use the output `rds_security_group_id` to
    add an ingress rule to allow your service to connect to the database, or add the security group
    of your service to the "allow_ingress_security_groups" variable. There _may_ be occasions where this
    parameter is needed.
  EOF
  type        = bool
  default     = false
}

variable "allow_ingress_security_groups" {
  description = <<EOF
    List of security group IDs to allow connections from. If `allow_ingress_from_all_private_subnets`
    is set to false, this list can be populated with the security group IDs of the services that need to
    connect to the database.
  EOF
  type        = list(string)
  default     = []
}

variable "database_port" {
  description = <<EOF
    Port the database listens on. If left as default, the default port for aurora-postgresql is 5432 and
    aurora-mysql is 3306. The port is also given as an output `database_port`.
  EOF
  type        = number
  default     = 0
  validation {
    condition     = var.database_port == 0 || (var.database_port > 1024 && var.database_port < 65536)
    error_message = "Database port must be 0 or between 1024 and 65535."
  }
}

variable "backtrack_window" {
  description = <<EOF
    The number of seconds to retain a backtrack window. The value represents the number
    of seconds you can roll back the database in a point-in-time recovery.

    This feature is only available for aurora-mysql, and only in select regions. See
    [Region and version availability](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html#AuroraMySQL.Managing.Backtrack.Availability)
    for details. Use of this setting is ignored for aurora-postgresql.

    The default is 8 hours (21,600 seconds), the maximum possible is 72 hours (259,200 seconds).

    Setting to 0 seconds disables it, but note that it cannot be enabled later, turning it on
    later requires a new cluster.

    There is a cost to Backtrack, although neglible.
  EOF
  type        = number
  default     = 21600
  validation {
    condition     = var.backtrack_window >= 0 && var.backtrack_window <= 259200
    error_message = "Backtrack window must be 0 or greater."
  }
}

variable "performance_insights_retention" {
  description = <<EOF
    Number of days for which to retain Performance Insights data. Must be 0, 7, 731, or a multiple of 31.
    A value of 0 means performance insights are disabled. See
    [Pricing and data retention for Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.Overview.cost.html)
    for all values. (Note that page talks about months, this value is in days, thus the 31 day multiple).

    Default is 7 days, which is in the free tier.
  EOF
  type        = number
  default     = 7
}

variable "enhanced_os_monitoring" {
  description = <<EOF
    Granularity, in seconds, of how frequently operating system metrics are collected and sent to CloudWatch. Valid values
    are 0 (disabled), 1, 5, 10, 15, 30, and 60 seconds. The default is 0, which disables enhanced monitoring. Enabling
    this will increase CloudWatch costs. See
    [OS metrics in Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_Monitoring-Available-OS-Metrics.html)
    for the list of metrics that will be collected.
  EOF
  type        = number
  default     = 0
  validation {
    condition     = can(index([0, 1, 5, 10, 15, 30, 60], var.enhanced_os_monitoring))
    error_message = "Enhanced OS monitoring must be one of 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "storage_type" {
  description = <<EOF
    One of "standard" or "io-optimized". Standard is the default, and is suitable for most workloads. See
    [Storage configurations for Amazon Aurora DB clusters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html#aurora-storage-type)
    for discussion on the two types.
  EOF
  type        = string
  default     = "standard"
  validation {
    condition     = can(regex("^(standard|io-optimized)$", var.storage_type))
    error_message = "Storage type must be one of 'standard' or 'io-optimized'."
  }
}

variable "create_cloudwatch_alarms" {
  description = "If set to true, cloudwatch alarms will be created for the database."
  type        = bool
  default     = true
}

variable "alarm_thresholds" {
  description = <<EOF
  Thresholds for the cloudwatch alarms. This is ignored if `create_cloudwatch_alarms` is false."

  The thresholds are:
  * cpu_utilization: The CPU utilization percentage that, if the average over five minutes is greater than this threshold,
    will trigger an alarm. Default is 85%.
  * acu_utilization: Only available in serverless configuration. The ACU utilization percentage that, if the average over
    five minutes is greater than this threshold, will trigger an alarm. After Aurora hits 100% it cannot scale more.
    Default is 85%.
  * free_memory: The amount of free memory in GB that, if the average over five minutes is less than this threshold,
    will trigger an alarm. Default is 0.5GB, which is sufficient for small workloads.
  * read_latency: the average amount of time taken to read data from the database, in seconds. If the average over five
    minutes is greater than this threshold, an alarm will be triggered. Default value is 100ms.
  * write_latency: the average amount of time taken to write data to the database, in seconds. If the average over five
    minutes is greater than this threshold, an alarm will be triggered. Default value is 100ms.
  * buffer_cache_hit_ratio: The percentage of requests that are served by the buffer cache, if the average over five minutes is less
    than this threshold, an alarm will be triggered. Default value is 85%.

  See the [Alarms and Actions](#alarms-and-actions) section of the README for more information.

  EOF
  type = object({
    cpu_utilization        = number
    acu_utilization        = number
    free_memory            = number
    read_latency           = number
    write_latency          = number
    buffer_cache_hit_ratio = number
  })
  default = {
    cpu_utilization        = 85
    acu_utilization        = 85
    free_memory            = 0.5
    read_latency           = 0.1
    write_latency          = 0.1
    buffer_cache_hit_ratio = 85
  }
}
