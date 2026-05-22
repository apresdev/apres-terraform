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

  name = "${module.apres_names.local_name}-ddb-sns-publisher"

  function_name = "sns_publisher"

  binary_name = "bootstrap"
  src_path    = "${path.module}/lambda/${local.function_name}/main.go"
  binary_path = abspath("${path.root}/tf_generated/${local.function_name}/lambda-ddb-sns-publisher.zip")

}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}
