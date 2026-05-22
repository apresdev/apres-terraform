locals {
  cwl_prefix = "/aws/rds/cluster"
  cwl_paths = var.engine == "aurora-postgresql" ? ["${local.cwl_prefix}/${local.name}/postgresql"] : [
    "${local.cwl_prefix}/${local.name}/audit",
    "${local.cwl_prefix}/${local.name}/error",
    "${local.cwl_prefix}/${local.name}/general",
    "${local.cwl_prefix}/${local.name}/slowquery"
  ]
}
# RDS will create the CWL group(s) automatically without a retention set, which means it'll grow forever, so
# pre-emptively create one with a valid retention period. For aurora-postgresql, there's only one group, for
# aurora-mysql there are four.
module "cloudwatchlogs" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  for_each    = toset(local.cwl_paths)
  source      = "https://github.com/apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.2.2"
  name        = local.name
  application = var.application
  component   = var.component
  environment = var.environment
  owner       = var.owner

  retention_in_days = 90
  path              = each.key
}