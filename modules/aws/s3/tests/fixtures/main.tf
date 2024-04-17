module "s3" {
  source     = "../../"
  name       = var.name
  environment = var.environment
  mfa_delete = false # Need this to be false or we can't delete it.
}