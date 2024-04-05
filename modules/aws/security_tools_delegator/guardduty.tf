# Delegate management to the audit account
resource "aws_guardduty_organization_admin_account" "default" {
  admin_account_id = var.audit_account_id
}