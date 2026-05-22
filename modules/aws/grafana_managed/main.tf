module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}

