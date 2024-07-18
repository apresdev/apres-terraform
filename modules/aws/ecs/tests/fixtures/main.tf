
locals {
  # If make_volume then create a simple 1GB volume to attach.
  volumes = var.make_volume ? [
    {
      name       = "ephemeral-storage"
      mountpoint = "/tmp"
      size_in_gb = 21 # min is 21GB
    }
  ] : []
}

module "ecs" {
  source      = "../../"
  name        = var.name
  application = var.application
  component   = var.component
  environment = var.environment
  # This container is built by apresdev/terraform-test-support and is a simple
  # web server with a static page.
  container_image_uri           = "767397774077.dkr.ecr.us-east-2.amazonaws.com/apres-hello-world:6333ff88fed52c2b7c531f35a56af28e21ec4ec5"
  deployment_target             = var.target
  vpc_environment_tag           = var.vpc_environment_tag
  ec2_use_instance_nvme_storage = var.ec2_use_instance_nvme_storage
  ec2_instance_type             = var.ec2_instance_type
  container_cpu_architecture    = "ARM64"
  ephemeral_volumes             = local.volumes
  container_port                = var.container_port

  # For testing we're going to decrease the health check intervals
  container_health_check_command      = ["CMD-SHELL", "curl -f localhost:8080 || exit 1"]
  container_health_check_interval     = 10
  container_health_check_timeout      = 5
  container_health_check_retries      = 3 # 3 * 5 = 15 seconds before failure
  container_health_check_start_period = 5

  # same with load balancers, setting this if create_load_balancer=false has no effect
  load_balancer_health_check_interval = 10

  # Use defaults explicitly to make it easier to debug tests
  cpu                  = 256
  memory               = 512
  create_load_balancer = var.create_load_balancer
  # saving for later - not for Fargate!
  #   container_tmpfs = [
  #     {
  #         containerPath = "/var/cache/nginx"
  #         size = 50
  #         mountOptions = ["rw"]
  #     },
  #     {
  #         containerPath = "/var/run"
  #         size = 50
  #         mountOptions = ["rw"]
  #     }
  #   ]
}