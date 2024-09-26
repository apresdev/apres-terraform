module "dynamodb" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"

  billing_mode = var.billing_mode

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  hash_key  = "pk"
  range_key = "sk"
  attributes = [
    {
      name = "pk"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    }
  ]
}
