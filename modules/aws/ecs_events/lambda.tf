# Grant the lambda permission to lookup tasks on all clusters and put metric data to CloudWatch
data "aws_iam_policy_document" "lambda" {
  #checkov:skip=CKV_AWS_356: False positive, need a * on the resource.
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTasks",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  role   = module.lambda.iam_role_name
  policy = data.aws_iam_policy_document.lambda.json
}

# Add lambda resource permissions for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default.arn
}

module "lambda" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/lambda?ref=rel/lambda/0.4.0"
  name        = var.name
  environment = var.environment
  application = var.application
  component   = "ECSEventsLambda"
  owner       = var.owner

  runtime     = "python3.9"
  binary_path = "${path.module}/lambda.py"
  handler     = "lambda.lambda_handler"
}