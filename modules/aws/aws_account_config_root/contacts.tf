resource "aws_account_primary_contact" "default" {
  address_line_1  = var.company_address_line_1
  address_line_2  = var.company_address_line_2
  city            = var.company_city
  company_name    = var.company_name
  country_code    = var.company_country_code
  state_or_region = var.company_state_or_region
  full_name       = var.primary_contact_full_name
  phone_number    = var.primary_contact_phone_number
  postal_code     = var.company_postal_code
}

locals {
  # Can specify DEFAULT or specific contact types, split them here since the resources are already created per AWS account
  operations_contact = contains(keys(var.alternate_contact_info), "default") ? var.alternate_contact_info["default"] : var.alternate_contact_info["operations"]
  security_contact   = contains(keys(var.alternate_contact_info), "default") ? var.alternate_contact_info["default"] : var.alternate_contact_info["security"]
  billing_contact    = contains(keys(var.alternate_contact_info), "default") ? var.alternate_contact_info["default"] : var.alternate_contact_info["billing"]

}

# To manage the contacts on the root account for the organization, we can't specify the account id.
# So the condition in each stanza below is to check if the account id in the list is the current one
# and if it is use nil instead.

# Set the operations contact for all the AWS accounts
resource "aws_account_alternate_contact" "operations" {
  for_each               = toset(data.aws_organizations_organization.default.accounts[*].id)
  alternate_contact_type = "OPERATIONS"
  account_id             = each.key == data.aws_caller_identity.default.account_id ? null : each.key
  name                   = local.operations_contact.name
  title                  = local.operations_contact.title
  email_address          = local.operations_contact.email_address
  phone_number           = local.operations_contact.phone_number
}

# Set the security contact for all the AWS accounts
resource "aws_account_alternate_contact" "security" {
  for_each               = toset(data.aws_organizations_organization.default.accounts[*].id)
  alternate_contact_type = "SECURITY"
  account_id             = each.key == data.aws_caller_identity.default.account_id ? null : each.key
  name                   = local.security_contact.name
  title                  = local.security_contact.title
  email_address          = local.security_contact.email_address
  phone_number           = local.security_contact.phone_number
}

# Set the operations contact for all the AWS accounts
resource "aws_account_alternate_contact" "billing" {
  for_each               = toset(data.aws_organizations_organization.default.accounts[*].id)
  alternate_contact_type = "BILLING"
  account_id             = each.key == data.aws_caller_identity.default.account_id ? null : each.key
  name                   = local.billing_contact.name
  title                  = local.billing_contact.title
  email_address          = local.billing_contact.email_address
  phone_number           = local.billing_contact.phone_number
}