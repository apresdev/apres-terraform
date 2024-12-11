locals {
  inspector_enable_resource_types = compact([
    var.inspector_enable_ec2_scanning ? "EC2" : null,
    var.inspector_enable_ecr_scanning ? "ECR" : null,
    var.inspector_enable_lambda_scanning ? "LAMBDA" : null,
    var.inspector_enable_lambda_code_scanning && var.inspector_enable_lambda_scanning ? "LAMBDA_CODE" : null,
  ])

  # in case the audit account is in the member list, remove it.
  member_accounts = setsubtract(var.inspector_member_accounts, [data.aws_caller_identity.current.account_id])
}

# Because of how AWS handles this we need to enable first the audit account,
# and then all member accounts
resource "aws_inspector2_enabler" "self" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = local.inspector_enable_resource_types
}

resource "aws_inspector2_member_association" "members" {
  for_each   = toset(local.member_accounts)
  account_id = each.value
  depends_on = [aws_inspector2_enabler.self]
}

resource "aws_inspector2_enabler" "members" {
  count          = length(local.member_accounts) > 0 ? 1 : 0
  account_ids    = local.member_accounts
  resource_types = local.inspector_enable_resource_types
  depends_on     = [aws_inspector2_member_association.members]
}