# IAM Roles in ECS are very confusing. There are two roles that are required for ECS to work properly, the first is
# the task execution role "ecs_task_execution_role", which is used to grant the Amazon ECS container and Fargate agents.
# Typically you shouldn't have to modify it. The second is the task role, which is used to grant the container permissions
# to the AWS services you need to interact with. This is the role that you will need to modify to grant your container
# access, pulled in as a variable and added to the task_role resource.

locals {
  # Secret ARN's may include the version or key, for IAM we only need the base ARN.
  # this loops through each ARN given, splits it by colon, then joins the first seven elements
  # (via splice) back together with a colon.
  # For example:
  #   arn:aws:secretsmanager:us-west-2:123456789012:secret:my-secret-123456::AWSPREVIOUS:
  # becomes:
  #   arn:aws:secretsmanager:us-west-2:123456789012:secret:my-secret-123456
  secret_arns = [
    for secret in var.container_secrets : join(":",
      slice(split(":", secret.secret_arn), 0, 7)
    )
  ]

}

# Create an IAM policy that will allow the task to Get and Decrypt secrets
# passed in. This is created with count so that we can use it dynamically
# in the IAM role.
data "aws_iam_policy_document" "task_execution_secrets_policy" {
  count = length(var.container_secrets) > 0 ? 1 : 0
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = distinct([for arn in local.secret_arns : arn])
  }
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    ]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ResourceAliases"
      # Merge the aliases, may have multiple values that are the same.
      values = distinct([for secret in var.container_secrets : secret.kms_key_alias])
    }
  }
}

# The task execution role grants the Amazon ECS container and Fargate agents permission to make AWS API calls on your behalf.
# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "task_execution_role" {
  name_prefix = "${local.name}-TaskExec"
  description = "Task Execution Role for ECS ${local.name}"
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
  dynamic "inline_policy" {
    for_each = data.aws_iam_policy_document.task_execution_secrets_policy
    content {
      name   = "${local.name}-TaskExecutionSecretsPolicy"
      policy = inline_policy.value.json
    }
  }
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-TaskExecutionRole"
    },
  )
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
  name_prefix        = "${local.name}-TaskRole"
  description        = "Task Role for ECS ${local.name}"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-TaskRole"
    },
  )
}

resource "aws_iam_role_policy" "task_role" {
  name   = "${local.name}-TaskPolicy"
  role   = aws_iam_role.task_role.name
  policy = var.ecs_task_iam_policy_document
}