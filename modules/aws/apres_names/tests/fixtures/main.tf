module "name" {
  source         = "../../"
  name           = var.name
  environment    = var.environment
  aws_account_id = var.aws_account_id
  region         = var.region
}