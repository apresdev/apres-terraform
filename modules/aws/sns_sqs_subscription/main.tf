# Adds the SQS queue as a subscriber to the topic
resource "aws_sns_topic_subscription" "default" {
  topic_arn            = var.sns_topic_arn
  protocol             = "sqs"
  endpoint             = var.sqs_queue_arn
  raw_message_delivery = var.raw_message_delivery
}
