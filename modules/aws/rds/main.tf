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
  # The Apres naming standard is that the local name starts with the environment, which
  # starts with a capital letter. Some of the RDS resources only support lower case letters
  # so for consistency we'll user lower case everywhere.
  name = lower(module.apres_names.local_name)

  # determine database port
  postgresql_port = 5432
  mysql_port      = 3306
  default_port    = var.engine == "aurora-mysql" ? local.mysql_port : local.postgresql_port
  port            = var.database_port == 0 ? local.default_port : var.database_port

  # calculate private and persistence subnet cidrs into lists
  private_cidrs                 = [for s in data.aws_subnet.private : s.cidr_block]
  persistence_cidrs             = [for s in data.aws_subnet.persistence : s.cidr_block]
  private_and_persistence_cidrs = concat(local.private_cidrs, local.persistence_cidrs)
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}
