# Current Identity
data "aws_caller_identity" "current" {}

# Current Region
data "aws_region" "current" {}

# Current Organization
data "aws_organizations_organization" "current" {}
