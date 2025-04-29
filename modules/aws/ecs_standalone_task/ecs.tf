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

  container_secrets = length(var.container_secrets) == 0 ? [] : [
    for secret in var.container_secrets : {
      name      = secret.name
      valueFrom = secret.secret_arn
    }
  ]
}

# Ideally we'd use an EBS volume for /tmp but the aws provider doesn't support that yet, so we use a docker volume
# instead, which is limited in size because of what the ECS host has - 20GB. Need to think about this more. The
# alternative would be to give the ECS task permissions to create a volume and mount it, but then cleanup would be
# a problem.
# https://github.com/hashicorp/terraform-provider-aws/issues/35279
#
resource "aws_ecs_task_definition" "default" {
  family = local.name
  # Reference for the following is https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html
  container_definitions = jsonencode(
    [
      {
        name                   = local.name
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
            awslogs-stream-prefix = local.name
          }
        }
        environment = local.container_environment_variables
        secrets     = local.container_secrets
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
  requires_compatibilities = ["FARGATE"]
  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )

  dynamic "volume" {
    for_each = local.container_volume_definition
    content {
      name = volume.value.name
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

resource "aws_security_group" "ecs" {
  #checkov:skip=CKV_AWS_382: False positive, ECS need full egress.
  #checkov:skip=CKV2_AWS_5: Ignore, this security group will be used for standalone tasks.
  name        = "${local.name}-ECS-Task"
  description = "ECS Task for ${local.name}"
  vpc_id      = data.aws_vpc.default.id
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-ECS-Task"
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

resource "aws_ecs_cluster" "default" {
  #checkov:skip=CKV_AWS_224:CloudWatch Logs are encrypted, just not with CMK's.
  name = local.name

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
      Name = local.name
    },
  )
}
