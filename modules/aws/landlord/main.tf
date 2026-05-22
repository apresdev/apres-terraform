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

  container_image_uri = "123456789012.dkr.ecr.us-east-2.amazonaws.com/landlord:46cd484772547d903f917d9bf14caf9aaf7955e2"
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}
