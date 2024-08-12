locals {
  owner       = "Testing"
  application = "UnitTests"
  component   = "SNS"
  tags = tomap({
    environment = var.environment
    managed-by  = "Terraform"
    application = local.application
    component   = local.component
    owner       = local.owner
  })
}

# The creates the SNS topic
# Note, the KMS key id must be the CMK id.
module "sns" {
  source = "../../../sns"

  name         = var.name
  display_name = var.name

  environment = var.environment
  owner       = local.owner
  application = local.application
  component   = local.component

}

# The creates the SQS queue.
# Note, the KMS key id must be the CMK id.
module "sqs" {
  source = "../../../sqs"

  name = var.name

  environment = var.environment
  owner       = local.owner
  application = local.application
  component   = local.component

}

# This auto-wires the SQS queue to be a subscriber to the SNS topic.
module "sns_sqs_subscription" {
  source = "../../"

  sns_topic_arn        = module.sns.topic_arn
  sqs_queue_arn        = module.sqs.queue_arn
  sqs_queue_url        = module.sqs.queue_url
  raw_message_delivery = true

  environment = var.environment
  owner       = local.owner
  application = local.application
  component   = local.component

  depends_on = [module.sns, module.sqs]
}
