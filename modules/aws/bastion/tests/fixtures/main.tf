module "bastion" {
  source      = "../../"
  name        = var.name
  application = var.application
  component   = var.component
  environment = var.environment

  instance_type       = "t4g.nano"
  number_hosts        = 1
  vpc_environment_tag = var.vpc_environment_tag
  install_packages    = ["postgresql16", "mariadb105"]
}