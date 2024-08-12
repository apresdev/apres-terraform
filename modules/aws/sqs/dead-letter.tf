resource "aws_sqs_queue" "deadletter" {
  name                       = "${local.queue_name}-deadletter"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  policy                     = var.policy
  fifo_queue                 = false

  # CKV_AWS_27: Ensure all data stored in the SQS queue is encrypted
  # sqs_managed_sse_enabled = false
  kms_master_key_id       = var.encryption_kms_key_id

  # For future reference, there appears to be a bug in the SQS terraform provider and/or the SQS Apis regarding configuring the 
  # `kms_data_key_reuse_period_seconds`, setting this to anything other than the default value causes the create queue to wait forever
  # which eventually causes the terraform script to fail.
  #
  # kms_data_key_reuse_period_seconds = var.key_reuse_period_seconds

  tags = merge(
    local.tags,
    tomap({
      Name = "${local.queue_name}-deadletter"
    })
  )

  depends_on = [data.aws_caller_identity.current]
}
