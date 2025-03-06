# We need to download the Lambda binary from GitHub. In future this should be supported
# by the Lambda module itself.

# Determine the URL for the asset we are interested in.
locals {
  lambda_name    = "lambda-grafana-configurator"
  architecture   = "arm64"
  asset_target   = "${local.lambda_name}.${local.architecture}.zip"
  asset_names    = [for v in data.github_release.lambda.assets : v.name]
  asset_index    = index(local.asset_names, local.asset_target)
  lambda_version = "1.4.0" # Release tag in GitHub to retrieve
  release_tag    = "v${local.lambda_version}"

  binary_path = abspath("${path.root}/tf_generated/${local.asset_target}")

  # Add the current region to the list of regions.
  regions = distinct(concat(var.regions, [data.aws_region.current.name]))
}

# Fetch the release info from GitHub
data "github_release" "lambda" {
  repository  = local.lambda_name
  owner       = "apresdev"
  retrieve_by = "tag"
  release_tag = local.release_tag
}


# Download the artifact
data "external" "artifact_download" {
  program = [
    "bash",
    "${path.module}/fetch-lambda.sh",
    local.binary_path,
    data.github_release.lambda.assets[local.asset_index].url,
    local.lambda_version
  ]
  depends_on = [data.github_release.lambda]
}

# Create the IAM policy for Lambda
data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "AllowReadFromSSM"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.grafana_config.arn]
  }
  statement {
    sid       = "AllowListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.dashboards-bucket.bucket_arn]
  }
  statement {
    sid    = "AllowReadFromS3"
    effect = "Allow"
    actions = [
      "s3:ListObjects",
      "s3:GetObject"
    ]
    resources = ["${module.dashboards-bucket.bucket_arn}/*"]
  }
  statement {
    sid    = "AllowWriteToS3"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${module.dashboards-bucket.bucket_arn}/backup/*"]
  }
  statement {
    sid       = "AllowAssumeRoleToRemoteAccounts"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = local.remote_arns
  }
}

resource "aws_iam_role_policy" "lambda" {
  role   = module.lambda.iam_role_name
  policy = data.aws_iam_policy_document.lambda.json
}

module "lambda" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/lambda?ref=rel/lambda/0.7.0"

  name        = "Grafana"
  environment = var.environment
  application = var.application
  component   = "Configurator"
  owner       = var.owner

  # runtime, binary_path, handler, etc
  runtime       = "provided.al2023"
  handler       = "configurator" # this is the binary name created by the build workflow in apresdev/lambda-configurator
  skip_zip      = true
  timeout       = 120 # 2 minutes
  binary_path   = local.binary_path
  architectures = [local.architecture]
  memory_size   = 256

  # Environment variables
  environment_variables = {
    ACCOUNT_IDS               = jsonencode(var.accounts)
    CUSTOM_METRICS_NAMESPACES = local.custom_metrics_namespaces
    CUSTOM_DASHBOARD_FOLDER   = var.custom_dashboard_folder_name
    DASHBOARD_BUCKET          = module.dashboards-bucket.bucket_id
    DASHBOARD_PREFIX          = local.dashboard_s3_prefix
    DEFAULT_REGION            = data.aws_region.current.name
    GRAFANA_URL               = "https://${aws_grafana_workspace.default.endpoint}"
    REGIONS                   = jsonencode(local.regions)
    REMOTE_ROLE_NAME          = local.remote_role_name
    SNS_TOPIC_ARN             = aws_sns_topic.default.arn
    SSM_PARAMETER_ARN         = aws_ssm_parameter.grafana_config.arn
  }

  # Need this or the lambda module will fail because the file isn't there yet.
  depends_on = [data.external.artifact_download]
}

module "lambda_scheduler" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/lambda_scheduler?ref=rel/lambda_scheduler/0.1.0"

  name        = var.name
  application = var.application
  component   = var.component
  owner       = var.owner
  environment = var.environment
  extra_tags  = var.extra_tags

  lambda_arn           = module.lambda.lambda_function_arn
  lambda_function_name = module.lambda.lambda_function_name
  # Run every hour
  schedule_expression = "cron(0 0/1 * * ? *)"
}


# This invokes the Lambda for initial configuration.
resource "aws_lambda_invocation" "grafana_configurator" {
  function_name = module.lambda.lambda_function_name
  # Input doesn't really matter since its getting the config from SSM but its required
  input     = jsonencode({})
  qualifier = "$LATEST"

  # If we don't put a trigger, the lambda will only execute if the arguments
  # here change. This trigger should force it to run on every apply.
  triggers = {
    api_token = aws_grafana_workspace_service_account_token.default.key
  }
}

