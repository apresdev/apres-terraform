module "landlord_dynamo" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source           = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/dynamodb?ref=rel/dynamodb/1.0.1"
  environment      = var.environment
  application      = var.application
  component        = var.component
  name             = var.name
  owner            = var.owner
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  billing_mode     = "PAY_PER_REQUEST"

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
    ,
    {
      name = "altName"
      type = "S"
    }
  ]

  global_secondary_indices = [
    {
      name     = "altNameIndex"
      hash_key = "altName"
    }
  ]
}


# Create an SNS topic where all DynamoDB CDC events will be published to.
module "landlord_cdc_topic" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/sns?ref=rel/sns/1.0.1"

  name         = "${var.name}-cdc"
  display_name = "Landlord Change Data Capture"

  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = var.component
}

# Create an SQS queue for all DynamoDB CDC events.
module "landlord_sync_queue" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/sqs?ref=rel/sqs/1.0.1"

  name = "${var.name}-cdc-sync"

  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = var.component
}

# Create a publisher that will take DynamoDB CDC events from the DynamoDB stream and publish them to the SNS topic
module "landlord_cdc_publisher" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  #checkov:skip=CKV_AWS_382:False positive, CDC lambda needs egress on 0/0.
  source = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/dynamodb_sns_publisher?ref=rel/dynamodb_sns_publisher/0.2.1"

  name       = "${var.name}-publish"
  topic_arn  = module.landlord_cdc_topic.topic_arn
  stream_arn = module.landlord_dynamo.stream_arn

  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = var.component
}

# Connect the sync queue and the CDC topic
module "landlord_sns_sqs_subscription" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/sns_sqs_subscription?ref=rel/sns_sqs_subscription/0.1.1"

  sns_topic_arn = module.landlord_cdc_topic.topic_arn
  sqs_queue_arn = module.landlord_sync_queue.queue_arn
  sqs_queue_url = module.landlord_sync_queue.queue_url

  environment = var.environment
  owner       = var.owner
  application = var.application
  component   = var.component
}





