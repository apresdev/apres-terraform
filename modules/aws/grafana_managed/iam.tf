# Policy that allows the Grafana service to assume the role defined below.
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:grafana:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/workspaces/*"]
    }
  }
}

# This is the role the Grafana service runs with.
resource "aws_iam_role" "grafana" {
  name_prefix        = local.name
  description        = "Role for Managed Grafana"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge(
    local.tags,
    {
      Name = "grafana-assume"
    },
  )
}

# Attach the CloudWatch permissions to the role
resource "aws_iam_role_policy_attachment" "assume" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaCloudWatchAccess"
}

locals {
  # Create a list of remote roles that Grafana will be able to assume.
  # The role name is hardcoded, defined in the aws_accounts_config_global module.
  # Concat the current account as well in case it wasn't set, and do a distinct in
  # case there's doubles.
  remote_role_name = "ApresGrafanaCrossAccountAccess"
  tmp_remote_arns = [
    for k, v in var.accounts : "arn:aws:iam::${v}:role/${local.remote_role_name}"
  ]
  remote_arns = distinct(concat(
    ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.remote_role_name}"],
    local.tmp_remote_arns
  ))

}

# This policy allows the Grafana workspace permision to assume role the target accounts
data "aws_iam_policy_document" "grafana_custom_policy" {
  statement {
    sid       = "AllowAssumeRoleToRemoteAccounts"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = local.remote_arns
  }
  statement {
    sid       = "AllowPublishToSNS"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.default.arn]
  }
}

resource "aws_iam_policy" "grafana" {
  name_prefix = local.name
  policy      = data.aws_iam_policy_document.grafana_custom_policy.json
  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

resource "aws_iam_role_policy_attachment" "assume_remote_accounts" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana.arn
}