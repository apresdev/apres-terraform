locals {
  # Convert environment variables from a map to a list with name/value pairs because that's how ECS wants them.
  merged_env_vars = merge(
    {
      "AWS_REGION"     = data.aws_region.current.name,
      "AWS_ACCOUNT_ID" = data.aws_caller_identity.current.account_id,
      "ENVIRONMENT"    = var.environment,
      "APPLICATION"    = var.application,
      "COMPONENT"      = var.component,
    },
    var.container_environment_variables
  )
  container_environment_variables = [for k, v in local.merged_env_vars : { name = k, value = v }]
}

# Ideally we'd use an EBS volume for /tmp but the aws provider doesn't support that yet, so we use a docker volume
# instead, which is limited in size because of what the ECS host has - 20GB. Need to think about this more. The
# alternative would be to give the ECS task permissions to create a volume and mount it, but then cleanup would be
# a problem.
# https://github.com/hashicorp/terraform-provider-aws/issues/35279
#
resource "aws_ecs_task_definition" "default" {
  family = local.container_name
  # Reference for the following is https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html
  container_definitions = jsonencode(
    [
      {
        name                   = local.container_name
        image                  = var.container_image_uri
        essential              = true
        readonlyRootFilesystem = true
        cpu                    = var.cpu
        memory                 = var.memory
        mountPoints            = local.container_mountpoints
        healthCheck            = local.container_health_check
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = local.cwl_log_group_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = local.container_name
          }
        }
        portMappings = local.container_port_mappings
        environment  = local.container_environment_variables
        linuxParameters = {
          tmpfs : var.container_tmpfs
        }
      }
    ]
  )

  cpu    = var.cpu
  memory = var.memory
  # See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.container_cpu_architecture
  }
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_execution_role.arn # for the ECS agent
  task_role_arn            = aws_iam_role.task_role.arn           # for the container
  requires_compatibilities = [var.deployment_target]
  tags = merge(
    local.tags,
    {
      Name = local.container_name
    },
  )

  # If Faragate and we have a volume, specify it here.
  dynamic "volume" {
    for_each = var.ephemeral_volumes
    content {
      name = volume.value.name
    }
  }
  # If EC2 and we have a volume, specify it here.
  dynamic "volume" {
    for_each = var.ephemeral_volumes
    content {
      name = volume.value.name
      docker_volume_configuration {
        scope = "task"
      }
    }
  }

  # Only create ephemeral storage, EBS, if on Fargate.
  dynamic "ephemeral_storage" {
    for_each = local.fargate_ephemeral_storage
    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }
}

resource "aws_ecs_service" "default" {
  # set dependency on the roles as per the comment in the aws_ecs_service docs.
  depends_on = [
    aws_ecs_capacity_provider.default[0],
    # Depend on these two or we can't destroy the service in Fargate
    aws_iam_role.task_role,
    aws_iam_role.task_execution_role,
    # Depend on these three else we can't destroy the service when on EC2
    aws_iam_role.ec2_instance_role[0],
    aws_iam_role_policy_attachment.ec2_ecs[0],
    aws_iam_role_policy_attachment.ec2_ssm[0],
  ]
  name            = local.container_name
  desired_count   = 1
  task_definition = aws_ecs_task_definition.default.arn
  cluster         = aws_ecs_cluster.default.id
  # launch_type and capacity_provider_strategy are mutually exclusive.
  launch_type = var.deployment_target == "FARGATE" ? "FARGATE" : null

  # Force a deployment on every "tf apply" to ensure the latest task definition is running.
  force_new_deployment = true
  triggers = {
    redeployment = plantimestamp()
  }

  # If there's autoscaling involved, the desired_count will be managed by the autoscaling policy so ignore it here.
  lifecycle {
    ignore_changes = [desired_count]
  }

  # spread the containers across the AZ's, only supported for EC2
  dynamic "ordered_placement_strategy" {
    for_each = local.ecs_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  # Set the capacity provider for the service, dynamically because it might not exist.
  dynamic "capacity_provider_strategy" {
    for_each = local.ecs_service_capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${var.environment}"
    },
  )
  propagate_tags = "SERVICE"

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  # Create this section dynamicall, but call out the listener ARN directly because we don't
  # know the ARN at the time the local section is created.
  dynamic "load_balancer" {
    for_each = local.load_balancer_config
    content {
      target_group_arn = aws_lb_target_group.default[0].arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-${var.environment}-ECS-Task"
  description = "Security group for ECS Task ${var.name}-${var.environment}"
  vpc_id      = data.aws_vpc.default.id
  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${var.environment}-ECS-Task"
    },
  )
  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add an ingress rule, only if the load balancer is created
resource "aws_security_group_rule" "ecs_ingress" {
  count                    = var.create_load_balancer ? 1 : 0
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.nlb[0].id
}

resource "aws_ecs_cluster" "default" {
  #checkov:skip=CKV_AWS_224:CloudWatch Logs are encrypted, just not with CMK's.
  name = "${var.name}-${var.environment}"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = local.cwl_log_group_name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${var.environment}"
    },
  )
}

resource "aws_ecs_capacity_provider" "default" {
  count      = local.use_ec2
  depends_on = [aws_autoscaling_group.ecs_asg[0]]
  name       = local.ecs_service_capacity_provider_name
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg[0].arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      status                 = "ENABLED"
      instance_warmup_period = 300 # default
      # max/min number instances provider can increase/decrease the ASG by.
      # TODO: this should be some ratio of min/max
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      target_capacity           = 100
    }
  }
  tags = merge(
    local.tags,
    {
      Name = local.ecs_service_capacity_provider_name
    },
  )
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  count              = local.use_ec2
  cluster_name       = aws_ecs_cluster.default.name
  capacity_providers = [aws_ecs_capacity_provider.default[0].name]
}