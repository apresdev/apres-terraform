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
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  topic_name = module.apres_names.local_name
  topic_arn  = "arn:aws:sns:${local.region}:${local.account_id}:${local.topic_name}"
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}