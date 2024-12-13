resource "aws_iam_instance_profile" "main" {
  name_prefix = local.name
  role        = aws_iam_role.main.name

  tags = merge(var.tags, {
    Name = local.name
  })
}

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "ManageNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [local.name]
    }
  }

  # Allow the intstance to fetch tags so it can use them for extra CloudWatch metrics
  dynamic "statement" {

    for_each = var.use_cloudwatch_agent ? ["x"] : []
    content {
      sid    = "AllowFetchTags"
      effect = "Allow"
      actions = [
        "ec2:DescribeTags"
      ]
      resources = [
        "*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.use_cloudwatch_agent ? ["x"] : []

    content {
      sid    = "CWAgentSSMParameter"
      effect = "Allow"
      actions = [
        "ssm:GetParameter"
      ]
      resources = [
        local.cwagent_param_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.use_cloudwatch_agent ? ["x"] : []

    content {
      sid    = "CWAgentMetrics"
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData"
      ]
      resources = [
        "*"
      ]
      condition {
        test     = "StringEquals"
        variable = "cloudwatch:namespace"
        values   = [var.cloudwatch_agent_configuration.namespace]
      }
    }
  }
}

resource "aws_iam_policy" "main" {
  name        = local.name
  description = "IAM policy for ${local.name} instance"
  policy      = data.aws_iam_policy_document.main.json
  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_iam_role" "main" {
  name_prefix = local.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

# add SSM support
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}