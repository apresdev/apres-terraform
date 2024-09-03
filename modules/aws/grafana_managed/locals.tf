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

  sns_topic_name = "${module.apres_names.local_name}-alerts"

  ssm_parameter_short_name = "${local.name}-config"
  ssm_parameter_name       = "/apres/grafana/${local.ssm_parameter_short_name}"

  dashboard_s3_prefix = "Apres"

  # These namespaces are emitted by Apres modules, add them so they'll be available for searching
  apres_namespaces          = ["Apres/ECS", "nat-instance"]
  custom_metrics_namespaces = join(",", concat(var.custom_cloudwatch_metrics_namespaces, local.apres_namespaces))
}

