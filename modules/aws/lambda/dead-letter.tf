# Note, we are not using the sqs module here as we ONLY want a dead-letter queue, not a main queue plus DLQ.
# In addition, we can control the lambda DLQ separately from an SQS DLQ (i.e. redrive policies, etc.)
resource "aws_sqs_queue" "deadletter" {
  count             = var.is_lambda_at_edge ? 0 : 1
  name              = "${local.name}-deadletter"
  fifo_queue        = false
  kms_master_key_id = "alias/apres/messaging"
  region            = local.region

  tags = merge(
    local.tags,
    tomap({
      Name = "${local.name}-deadletter"
    })
  )
}

# move resource from a single object to count
moved {
  from = aws_sqs_queue.deadletter
  to   = aws_sqs_queue.securityhub[0]
}