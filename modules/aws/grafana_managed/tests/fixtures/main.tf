module "grafana" {
  source = "../../"

  name        = var.name
  environment = var.environment
  application = "Observability"
  component   = "Grafana"
  owner       = "Engineering"

  accounts = var.accounts
  regions  = var.regions

  admin_users  = var.admin_users
  editor_users = var.editor_users
  viewer_users = var.viewer_users

  admin_groups  = var.admin_groups
  editor_groups = var.editor_groups
  viewer_groups = var.viewer_groups

  custom_dashboard_folder_name = "Custom"

  # Need the depends_on so the cloudwatch alarm gets created first, and can
  # be found by the configurator
  depends_on = [module.cloudwatch_alarm]
}

module "cloudwatch_alarm" {
  source      = "../../../cloudwatch_alarm"
  name        = var.name
  environment = var.environment
  application = "Observability"
  component   = "Alarm"
  owner       = "Engineering"

  severity    = "SEV1"
  runbook     = "https://runbook.example.com"
  description = "This is a unit test alarm"
  dimensions = {
    AutoScalingGroupName = "vpc-nat-az1"
  }
  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
}