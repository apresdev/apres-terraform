# Note, we are not using the sqs module here as we ONLY want a dead-letter queue, not a main queue plus DLQ.
# In addition, we can control the lambda DLQ separately from an SQS DLQ (i.e. redrive policies, etc.)
resource "aws_sqs_queue" "deadletter" {
  name              = "${local.name}-deadletter"
  fifo_queue        = false
  kms_master_key_id = "alias/apres/messaging"

  tags = merge(
    local.tags,
    tomap({
      Name = "${local.name}-deadletter"
    })
  )

}
