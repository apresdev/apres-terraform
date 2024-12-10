resource "aws_inspector2_delegated_admin_account" "audit" {
  account_id = var.audit_account_id
}