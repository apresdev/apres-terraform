locals {
  owner       = "Testing"
  application = "UnitTests"
  component   = "SNS"
}

module "sns" {
  source = "../../"

  name         = var.name
  display_name = var.display_name

  environment = var.environment
  owner       = local.owner
  application = local.application
  component   = local.component
}
