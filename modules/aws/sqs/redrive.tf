resource "aws_sqs_queue_redrive_allow_policy" "deadletter" {
  queue_url = aws_sqs_queue.deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.default.arn]
  })

  depends_on = [aws_sqs_queue.default, aws_sqs_queue.deadletter]
}
