module "sqs" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"
}
