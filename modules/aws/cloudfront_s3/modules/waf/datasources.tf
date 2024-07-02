# Fetch the current AWS account
data "aws_caller_identity" "current" {}

# Fetch the current region
data "aws_region" "current" {}

data "aws_canonical_user_id" "current" {}

data "aws_cloudfront_log_delivery_canonical_user_id" "current" {}