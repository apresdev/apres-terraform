locals {
  tags = merge(
    var.default_tags,
    tomap({
      environment = var.environment
      managed-by  = "Terraform"
      application = var.application
      component   = var.component
      owner       = var.owner
    })
  )

  lambda_version = "0.1.5"
  architecture   = "x86_64"

  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  lambda_name = "${lower(var.name)}-ddb-sns-publisher"

  function_name = "sns_publisher"

  binary_name = "bootstrap"
  src_path    = "${path.module}/lambda/${local.function_name}/main.go"
  binary_path = abspath("${path.root}/tf_generated/${local.function_name}/lambda-ddb-sns-publisher.zip")

}
