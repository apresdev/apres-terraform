# IAM Roles in ECS are very confusing. There are two roles that are required for ECS to work properly, the first is
# the task execution role "ecs_task_execution_role", which is used to grant the Amazon ECS container and Fargate agents.
# Typically you shouldn't have to modify it. The second is the task role, which is used to grant the container permissions
# to the AWS services you need to interact with. This is the role that you will need to modify to grant your container
# access, pulled in as a variable and added to the task_role resource.

# The task execution role grants the Amazon ECS container and Fargate agents permission to make AWS API calls on your behalf.
# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "task_execution_role" {
  name = "${var.name}-${var.environment}-TaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${var.environment}-TaskExecutionRole"
    },
  )
}

# This is the assume role policy that allows ECS to delegate permissions to the task.
data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-${var.environment}-TaskRole"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  inline_policy {
    name   = "${var.name}-${var.environment}-TaskPolicy"
    policy = var.ecs_task_iam_policy_document
  }
  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${var.environment}-TaskRole"
    },
  )
}

