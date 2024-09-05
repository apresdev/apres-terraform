# Fetch the current AWS account
data "aws_caller_identity" "current" {}

# Fetch the current region
data "aws_region" "current" {}

data "aws_kms_alias" "messaging" {
  name = "alias/apres/messaging"
}