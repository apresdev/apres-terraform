# This connects the DynamoDb stream to the lambda function.
# Note, we want the batch size to be 1 as this is what the lambda function expects.
resource "aws_lambda_event_source_mapping" "default" {
  event_source_arn  = var.stream_arn
  function_name     = module.lambda.lambda_function_arn
  starting_position = "TRIM_HORIZON"
  batch_size        = 1

  depends_on = [module.lambda]
}
