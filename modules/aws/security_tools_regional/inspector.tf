locals {
  inspector_enable_resource_types = compact([
    var.inspector_enable_ec2_scanning ? "EC2" : null,
    var.inspector_enable_ecr_scanning ? "ECR" : null,
    var.inspector_enable_lambda_scanning ? "LAMBDA" : null,
    var.inspector_enable_lambda_code_scanning && var.inspector_enable_lambda_scanning ? "LAMBDA_CODE" : null,
  ])
}

# Because of how AWS handles this we need to enable first the audit account,
# and then all member accounts
resource "aws_inspector2_enabler" "self" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = local.inspector_enable_resource_types
}

resource "aws_inspector2_enabler" "members" {
  count          = length(var.inspector_member_accounts) > 0 ? 1 : 0
  account_ids    = var.inspector_member_accounts
  resource_types = local.inspector_enable_resource_types
  depends_on     = [aws_inspector2_enabler.self]
}