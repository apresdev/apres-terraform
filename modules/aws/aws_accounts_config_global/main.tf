locals {
  tags = {
    application = "Observability"
    component   = "CloudWatch"
    environment = "Global"
    owner       = "Engineering"
    managed-by  = "Terraform"
  }
}


# Set a password policy for the account. This matches the two standards:
# * AWS Foundational Security Best Practices v1.0.0,
# * CIS AWS Foundations Benchmark v1.2.0
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
}

# Add IAM artifacts for Grafana in the monitoring account to access CloudWatch
# in this account. We don't have a named role for Grafana, so we use the root.
data "aws_iam_policy_document" "cloudwatch_assume_role" {
  count = var.monitoring_account_id == "" ? 0 : 1
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.monitoring_account_id}:root"]
    }
  }
}

resource "aws_iam_role" "cloudwatch" {
  count = var.monitoring_account_id == "" ? 0 : 1
  # Hard coding the name because it needs to be used in the monitoring account
  name               = "ApresGrafanaCrossAccountAccess"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role[0].json
  tags = merge(
    local.tags,
    {
      Name = "ApresGrafanaCrossAccountAccess"
    },
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count      = var.monitoring_account_id == "" ? 0 : 1
  role       = aws_iam_role.cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Add IAM artifacts for the Lambda in the monitoring account to access CloudWatch
# Alarms in this account.
data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.monitoring_account_id == "" ? 0 : 1
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.monitoring_account_id}:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${var.monitoring_account_id}:role/ApresGrafanaConfiguratorLambda"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  count              = var.monitoring_account_id == "" ? 0 : 1
  name               = "ApresGrafanaConfiguratorCrossAccountAccess"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json
  tags = merge(
    local.tags,
    {
      Name = "ApresGrafanaConfiguratorCrossAccountAccess"
    },
  )
}

resource "aws_iam_role_policy_attachment" "lambda" {
  count      = var.monitoring_account_id == "" ? 0 : 1
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}