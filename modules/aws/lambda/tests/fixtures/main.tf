locals {
  archive_path = var.use_zip ? "${path.module}/lambda.zip" : ""
}

data "archive_file" "lambda" {
  count       = var.use_zip ? 1 : 0
  type        = "zip"
  source_file = "lambda.py"
  output_path = local.archive_path
}


module "lambda" {
  source = "../../"

  name    = var.name
  runtime = "python3.14"
  # if use_zip set this to empty string
  source_file = var.use_zip ? "" : "lambda.py"
  # if use_zip use these two variables
  zip_file      = var.use_zip ? local.archive_path : ""
  zip_file_hash = var.use_zip ? data.archive_file.lambda[0].output_md5 : ""

  handler       = "lambda.lambda_handler"
  architectures = ["x86_64"]

  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "LambdaTest"

  environment_variables = {
    "OTHER" : "true"
  }

  is_lambda_at_edge = var.is_lambda_at_edge

  vpc = {
    enabled         = var.enable_vpc
    environment_tag = var.vpc_environment_tag
  }
}
