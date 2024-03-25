

module "cloudwatchlogs" {
  source            = "../../"
  name              = var.name
  path              = var.path
  retention_in_days = var.retention_in_days
  environment = var.environment
}