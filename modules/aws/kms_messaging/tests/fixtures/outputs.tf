
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

output "cmk_alias" {
  value = module.kms_messaging.cmk_alias
}

output "cmk_arn" {
  value = module.kms_messaging.cmk_arn
}