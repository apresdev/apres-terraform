# Create a simple ECS cluster with a container that crashes constantly
# The goodbye world container is defined in
# https://github.com/apresdev/terraform-test-support
# and sleeps for 10 seconds, and then exits with a status code of 1.

module "goodbyeworld" {
  #checkov:skip=CKV_AWS_103: False positive.
  source                     = "../../../ecs"
  name                       = "goodbyecs"
  vpc_environment_tag        = var.vpc_environment_tag # not used but still required
  environment                = var.environment
  application                = var.application
  component                  = var.component
  deployment_target          = "FARGATE"
  container_cpu_architecture = "ARM64"
  container_image_uri        = "123456789012.dkr.ecr.us-east-2.amazonaws.com/apres-goodbye-world:497b35d65db375ef32e07de7a3940ce1ed2269b3"
  create_load_balancer       = false
}

module "ecs_events" {
  source      = "../../../ecs_events"
  name        = "goodbyeevents"
  environment = var.environment
  application = var.application
  component   = var.component
}
