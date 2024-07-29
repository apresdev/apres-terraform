# Get the Organization
data "aws_organizations_organization" "default" {}

# Current account
data "aws_caller_identity" "default" {}
