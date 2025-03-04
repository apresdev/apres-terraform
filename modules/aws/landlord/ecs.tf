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
  # Should not have a cert here!
  #load_balancer_ssl_cert_arn = module.acm_public_cert_api.certificate_arn
  load_balancer_port = 80
  container_port     = 8080

  container_environment_variables = {
    LANDLORD_DB_TABLE_NAME     = module.landlord_dynamo.table_name
    LANDLORD_APP_URL           = var.app_url
    LANDLORD_APP_NAME          = var.app_name
    LANDLORD_APP_ADMIN_EMAIL   = var.app_admin_email
    LANDLORD_LISTEN_ADDR       = "0.0.0.0:8080"
    LANDLORD_DEFAULT_USER_POOL = local.user_pool_name
  }

  ecs_task_iam_policy_document = data.aws_iam_policy_document.ecs_task.json
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
    LANDLORD_DB_TABLE_NAME     = module.landlord_dynamo.table_name
    LANDLORD_APP_URL           = var.app_url
    LANDLORD_CONSOLE_URL       = "https://${lower(var.name)}.${var.hosted_zone_name}" # was: var.console_url
    LANDLORD_APP_NAME          = var.app_name
    LANDLORD_APP_ADMIN_EMAIL   = var.app_admin_email
    LANDLORD_LISTEN_ADDR       = "0.0.0.0:8080"
    LANDLORD_DEFAULT_USER_POOL = local.user_pool_name
  }

  ecs_task_iam_policy_document = data.aws_iam_policy_document.ecs_task.json
}
