variable "name" {
  description = "Name of the database cluster."
  type        = string
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "UnitTest"
}

variable "vpc_environment_tag" {
  description = "The tag to use for the VPC environment."
  type        = string
  default     = "Test"
}

variable "engine" {
  description = "The database engine to use."
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "The version of the database engine to use."
  type        = string
  default     = "16.6"
}

variable "instance_class" {
  description = "The instance class to use for the database."
  type        = string
  default     = "db.t3.medium"
}

variable "db_parameter_group_family" {
  description = "The family of the database parameter group."
  type        = string
  default     = "aurora-postgresql16"
}

variable "serverless" {
  description = "Whether to use a serverless database."
  type        = bool
  default     = true
}

variable "serverless_scaling" {
  description = "The scaling configuration for the serverless database."
  type = object({
    min_capacity             = number
    max_capacity             = number
    seconds_until_auto_pause = number
  })
  default = {
    min_capacity             = 0
    max_capacity             = 2
    seconds_until_auto_pause = 300
  }
}

variable "allow_ingress_security_groups" {
  description = "The security groups to allow ingress from."
  type        = list(string)
  default     = []
}

variable "allow_ingress_from_all_private_subnets" {
  description = "Whether to allow ingress from all private subnets."
  type        = bool
  default     = false
}

variable "backup_window" {
  type        = string
  description = "The UTC time window to perform backups in."
  default     = "06:00-06:30"
}

variable "maintenance_window" {
  type        = string
  description = "The UTC time window to perform maintenance in."
  default     = "Sun:07:00-Sun:07:30"
}

variable "database_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "db_cluster_parameters" {
  description = "The parameters to set on the database cluster."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "db_instance_parameters" {
  description = "The parameters to set on the database instances."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}