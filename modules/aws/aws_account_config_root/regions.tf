
# We need a list of accounts and regions to enable for the organization. From variables we have
#  enable_regions = {
#    "default" = ["us-east-1", "us-east-2"],
#    "123456789012"    = ["us-east-1", "us-west-2", "us-west-1", "ca-central-1"]
#  }
# and from data.aws_organizations_organization.default.accounts[*].id we have a list of account ids
locals {
  # This will give us a list of account ids and regions to enable for the organization
  #   account_regions = [for account in data.aws_organizations_organization.default.accounts[*].id : {
  #     account_id = account
  #     regions    = lookup(var.enable_regions, account, var.enable_regions["default"])
  #   }]


  # We could do the next two in one section but it gets hard to read.
  # Create a list of account id's with list of regions, using the default if it doesn't exist. Sample output:
  # [
  #   { "account_id" = "123456789012", "region" = ["us-east-1", "us-west-2", "us-west-1", "ca-central-1"] },
  #   { "account_id" = "234567890123", "region" = ["us-east-1", "us-east-2"]}
  # ]
  account_regions = [for account_id in data.aws_organizations_organization.default.accounts[*].id : {
    account_id = account_id
    region     = lookup(var.enable_regions, account_id, var.enable_regions["default"])
  }]

  # Now create a list of account/region specifics and merge it. The ... at the end allow us to merge an array
  # Sample output:
  # {
  #   "123456789012/ca-central-1" = {
  #     account_id = "123456789012"
  #     region     = "ca-central-1"
  #   },
  #   "123456789012/us-east-1"    = {
  #      account_id = "123456789012"
  #      region     = "us-east-1"
  #    },
  #    ...
  # }
  account_region_pairs = merge([for account_region in local.account_regions : {
    for region in account_region.region : "${account_region.account_id}/${region}" => {
      account_id = account_region.account_id
      region     = region
    }
  }]...)

}



resource "aws_account_region" "default" {
  for_each    = local.account_region_pairs
  account_id  = each.value.account_id
  region_name = each.value.region
  enabled     = true
}