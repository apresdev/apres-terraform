# Ideally, we want to download the lambda executable from the github release, rather than compiling it during the module execution process.
# Terraform has recommendations on how to install additional binaries:
# (See: https://developer.hashicorp.com/terraform/cloud-docs/run/install-software)
module "lambda" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/lambda?ref=rel/lambda/0.3.0"

  name          = var.name
  description   = "DynamoDB stream to SNS publisher"
  binary_path   = local.binary_path
  memory_size   = 128
  runtime       = "provided.al2023"
  handler       = "bootstrap"
  skip_zip      = true
  architectures = [local.architecture]

  environment_variables = {
    APRES_SNS_TOPIC = var.topic_arn
  }

  lambda_regional_environment = var.lambda_regional_environment

  environment = var.environment
  component   = var.component
  application = var.application
  owner       = var.owner


  depends_on = [data.external.artifact_download]
}

# Fetch the release info from GitHub
data "github_release" "lambda" {
  repository  = "lambda-ddb-sns-publisher"
  owner       = "apresdev"
  retrieve_by = "tag"
  release_tag = "v${local.lambda_version}"
}

# Determine the URL for the asset we are interested in.
locals {
  asset_target = local.architecture == "arm64" ? "lambda-ddb-sns-publisher.arm64.zip" : "lambda-ddb-sns-publisher.amd64.zip"
  asset_names  = [for v in data.github_release.lambda.assets : v.name]
  asset_index  = index(local.asset_names, local.asset_target)
  asset_url    = data.github_release.lambda.assets[local.asset_index].url
}

output "lambda_artifact" {
  value = local.asset_target
}

# Download the asset.
# TODO: We might want to consider creating our own terraform provider for downloading GitHub artifacts.  Running curl locally is sub-optimal.
data "external" "artifact_download" {

  program = [
    "bash",
    "${path.module}/fetch-lambda.sh",
    local.binary_path,
    local.asset_url,
    local.lambda_version
  ]

  depends_on = [data.github_release.lambda]
}
