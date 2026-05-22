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

  # Create a mount point, if it was passed in as a variable. Do this as a local because it's going
  # into a jsonencode() in the task definition.
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

  # Create an array for the load balancer, so we can create it dynamically
  load_balancer_config = var.create_load_balancer ? [
    {
      container_name = local.name
      container_port = var.container_port
    }
  ] : []

  # If fargate, we need ephemeral storage, so create it dynamically.
  fargate_ephemeral_storage = var.deployment_target == "FARGATE" && length(var.ephemeral_volumes) > 0 ? [
    {
      size_in_gib = var.ephemeral_volumes[0].size_in_gb
    }
  ] : []

  # For the "volume" section in the ECS task definition, the contents differ in an incompatible way
  # between fargate and EC2. Because we can't manage that condition in the task definition,
  # we create two separate identical volume definitions here
  # and then specify both in the task definition, and only one will populate. It's a hack.
  #
  # First the fargate one
  container_volume_definition_fargate = var.deployment_target == "FARGATE" && length(var.ephemeral_volumes) > 0 ? [
    {
      name = var.ephemeral_volumes[0].name
    }
  ] : []
  # and the EC2 definition.
  container_volume_definition_ec2 = var.deployment_target == "EC2" && length(var.ephemeral_volumes) > 0 ? [
    {
      name = var.ephemeral_volumes[0].name
    }
  ] : []

  # Create the capacity provider strategy for the ecs service dynamically. We only need the name, not the ARN,
  # so set the name here.
  ecs_service_capacity_provider_name = "${var.name}-${var.environment}-CapacityProvider"
  ecs_service_capacity_provider_strategy = local.use_ec2 == 1 ? [
    {
      capacity_provider = local.ecs_service_capacity_provider_name
      weight            = 1
    }
  ] : []

  # ECS placement strategies are only supported for EC2
  ecs_placement_strategy = local.use_ec2 == 1 ? [
    {
      type  = "spread"
      field = "attribute:ecs.availability-zone"
    }
  ] : []

  # Port mappings for container definitions
  container_port_mappings = var.container_port != -1 ? [
    {
      containerPort = var.container_port
      protocol      = "tcp"
    }
  ] : []

}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}
