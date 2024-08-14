# Delegate Security Hub to the audit account


locals {
  current_region = data.aws_region.current.name
}
# Moved in 0.3 so we can support multiple regions
moved {
  from = aws_securityhub_organization_admin_account.securityhub
  to   = aws_securityhub_organization_admin_account.securityhub[0]
}

resource "aws_securityhub_organization_admin_account" "securityhub" {
  count            = var.primary_region == local.current_region ? 1 : 0
  admin_account_id = var.audit_account_id
}