locals {
  local_name = "${var.environment}-${var.name}"

  account = var.aws_account_id == "" ? data.aws_caller_identity.current.account_id : var.aws_account_id
  region  = var.region == "" ? data.aws_region.current.region : var.region

  global_name = "${local.account}-${var.environment}-${local.region}-${var.name}"
}