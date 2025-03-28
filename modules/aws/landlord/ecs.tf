locals {
  user_profile_fields_map = {
    fields = var.user_profile_fields
  }
  user_profile_fields_json   = jsonencode(local.user_profile_fields_map)
  user_profile_fields_base64 = base64encode(local.user_profile_fields_json)

  tenant_profile_fields_map = {
    fields = var.tenant_profile_fields
  }
  tenant_profile_fields_json   = jsonencode(local.tenant_profile_fields_map)
  tenant_profile_fields_base64 = base64encode(local.tenant_profile_fields_json)
}

module "landlord_api_ecs" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  #checkov:skip=CKV_AWS_23:False positive
  #checkov:skip=CKV_AWS_2:Load balancer protocol is HTTPS
  #checkov:skip=CKV_AWS_103:LB default is TLS 1.2
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/ecs?ref=rel/ecs/2.1.3"
  name        = "${var.name}-API"
  application = var.application
  component   = var.component
  environment = var.environment

  container_image_uri        = local.container_image_uri
  deployment_target          = "FARGATE"
  container_cpu_architecture = "X86_64"
  vpc_environment_tag        = var.vpc_environment_tag

  create_load_balancer    = true
  load_balancer_is_public = false
  load_balancer_port      = 80
  container_port          = 8080

  container_environment_variables = {
    LANDLORD_DB_TABLE_NAME             = module.landlord_dynamo.table_name
    LANDLORD_APP_URL                   = var.app_url
    LANDLORD_APP_NAME                  = var.app_name
    LANDLORD_APP_ADMIN_EMAIL           = var.app_admin_email
    LANDLORD_LISTEN_ADDR               = "0.0.0.0:8080"
    LANDLORD_DEFAULT_USER_POOL         = local.user_pool_name
    LANDLORD_USER_PROFILE_DEFINITION   = local.user_profile_fields_base64
    LANDLORD_TENANT_PROFILE_DEFINITION = local.tenant_profile_fields_base64
  }

  ecs_task_iam_policy_document = data.aws_iam_policy_document.ecs_task.json

  ecs_autoscale_min_instances = var.ecs_api_min_instances
  ecs_autoscale_max_instances = var.ecs_api_max_instances
}

module "landlord_console_ecs" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  #checkov:skip=CKV_AWS_23:False positive
  #checkov:skip=CKV_AWS_2:Load balancer protocol is HTTPS
  #checkov:skip=CKV_AWS_103:LB default is TLS 1.2
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/ecs?ref=rel/ecs/2.1.3"
  name        = "${var.name}-Console"
  application = var.application
  component   = var.component
  environment = var.environment

  container_image_uri        = local.container_image_uri
  deployment_target          = "FARGATE"
  container_cpu_architecture = "X86_64"
  vpc_environment_tag        = var.vpc_environment_tag

  create_load_balancer       = true
  load_balancer_is_public    = true
  load_balancer_ssl_cert_arn = module.acm_public_cert_console.certificate_arn
  load_balancer_port         = 443
  container_port             = 8080

  container_environment_variables = {
    LANDLORD_DB_TABLE_NAME             = module.landlord_dynamo.table_name
    LANDLORD_APP_URL                   = var.app_url
    LANDLORD_CONSOLE_URL               = "https://${lower(var.name)}.${var.hosted_zone_name}" # was: var.console_url
    LANDLORD_APP_NAME                  = var.app_name
    LANDLORD_APP_ADMIN_EMAIL           = var.app_admin_email
    LANDLORD_LISTEN_ADDR               = "0.0.0.0:8080"
    LANDLORD_DEFAULT_USER_POOL         = local.user_pool_name
    LANDLORD_USER_PROFILE_DEFINITION   = local.user_profile_fields_base64
    LANDLORD_TENANT_PROFILE_DEFINITION = local.tenant_profile_fields_base64
  }

  ecs_task_iam_policy_document = data.aws_iam_policy_document.ecs_task.json

  ecs_autoscale_min_instances = var.ecs_console_min_instances
  ecs_autoscale_max_instances = var.ecs_console_max_instances
}
