locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = var.component
      "owner"       = var.owner
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )

  cwl_log_group_name = var.cloudwatch_logs_group_name == "" ? "${lower(var.application)}/${lower(var.name)}-${lower(var.environment)}" : var.cloudwatch_logs_group_name

  # Create a mountpoint, if it was passed in as a variable. Do this as a local because it's going
  # into a jsonencode() in the task defintion.
  container_mountpoints = length(var.ephemeral_volumes) == 0 ? [] : [
    {
      sourceVolume  = var.ephemeral_volumes[0].name
      containerPath = var.ephemeral_volumes[0].mountpoint
      readOnly      = false
    }
  ]

  # Create the health check, if it exists. Do this as a local because it's going into a jsonencode() in the task definition.
  container_health_check = length(var.container_health_check_command) == 0 ? null : {
    command     = var.container_health_check_command
    interval    = var.container_health_check_interval
    timeout     = var.container_health_check_timeout
    retries     = var.container_health_check_retries
    startPeriod = var.container_health_check_start_period
  }

  name = module.apres_names.local_name

  # If fargate, we need ephemeral strorage, so create it dynamically.
  fargate_ephemeral_storage = length(var.ephemeral_volumes) > 0 ? [
    {
      size_in_gib = var.ephemeral_volumes[0].size_in_gb
    }
  ] : []

  container_volume_definition = length(var.ephemeral_volumes) > 0 ? [
    {
      name = var.ephemeral_volumes[0].name
    }
  ] : []

}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}