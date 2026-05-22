
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

resource "aws_secretsmanager_secret" "default" {
  #checkov:skip=CKV_AWS_149: Ignore CMS key for testing
  #checkov:skip=CKV2_AWS_57: Ignore rotation for testing
  count                   = var.create_secret ? 1 : 0
  name                    = var.name
  recovery_window_in_days = 0 # don't care about recovery
}

resource "aws_secretsmanager_secret_version" "default" {
  count     = var.create_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.default[0].id
  secret_string = jsonencode({
    "username" = "admin"
    "password" = var.name
  })
}

module "ecs_standalone_task" {
  source      = "../../"
  name        = var.name
  application = var.application
  component   = var.component
  environment = var.environment
  # This container is built by apresdev/terraform-test-support and is a simple
  # task that runs for 10 seconds and exits with a non-zero code.
  container_image_uri        = "123456789012.dkr.ecr.us-east-2.amazonaws.com/apres-goodbye-world:497b35d65db375ef32e07de7a3940ce1ed2269b3"
  vpc_environment_tag        = var.vpc_environment_tag
  container_cpu_architecture = "ARM64"
  ephemeral_volumes          = local.volumes

  # For testing we're going to decrease the health check intervals
  container_health_check_command      = ["CMD-SHELL", "curl -f localhost:8080 || exit 1"]
  container_health_check_interval     = 10
  container_health_check_timeout      = 5
  container_health_check_retries      = 3 # 3 * 5 = 15 seconds before failure
  container_health_check_start_period = 5

  # Use defaults explicitly to make it easier to debug tests
  cpu    = 256
  memory = 512
  container_secrets = var.create_secret ? [
    {
      name          = var.name
      secret_arn    = aws_secretsmanager_secret.default[0].arn
      kms_key_alias = "aws/secretsmanager"
    }
  ] : []

  container_environment_variables = {
    TEST_ENV_VAR = "test"
  }
}