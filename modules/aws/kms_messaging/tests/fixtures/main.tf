locals {
  owner       = "Testing"
  application = "UnitTests"
  component   = "SNS"
}

module "kms_messaging" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  owner       = local.owner
  application = local.application
  component   = local.component
}
