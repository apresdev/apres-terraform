# Delegate Security Hub to the audit account
resource "aws_securityhub_organization_admin_account" "securityhub" {
  admin_account_id = var.audit_account_id
}