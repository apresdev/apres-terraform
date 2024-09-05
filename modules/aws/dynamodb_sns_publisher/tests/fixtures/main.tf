module "dynamodb" {
  source      = "../../../dynamodb"
  name        = var.name
  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"

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

module "sns" {
  source = "../../../sns"

  name         = var.name
  display_name = var.name

  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"
}

module "sqs" {
  source = "../../../sqs"

  name = var.name

  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"
}

module "dynamodb_sns_publisher" {
  source = "../../"

  name       = var.name
  topic_arn  = module.sns.topic_arn
  stream_arn = module.dynamodb.stream_arn

  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"
}

module "sns_sqs_subscription" {
  source = "../../../sns_sqs_subscription"

  sns_topic_arn = module.sns.topic_arn
  sqs_queue_arn = module.sqs.queue_arn
  sqs_queue_url = module.sqs.queue_url

  environment = var.environment
  owner       = "Testing"
  application = "UnitTests"
  component   = "DDB"
}
