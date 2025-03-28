locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = var.component
      "owner"       = var.owner
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )
  name = module.apres_names.local_name

  console_domain_name = "${lower(var.name)}.${var.hosted_zone_name}"
  api_domain_name     = "${lower(var.name)}-api.${var.hosted_zone_name}"

  container_image_uri = "767397774077.dkr.ecr.us-east-2.amazonaws.com/landlord:8ab995053fe8f5e2e8c75fd2e7f61c0385083335"
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/1.0.0"
  name        = var.name
  environment = var.environment
}
