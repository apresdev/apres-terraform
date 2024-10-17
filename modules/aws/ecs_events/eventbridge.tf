resource "aws_cloudwatch_event_rule" "default" {
  name_prefix = "${var.name}-"
  description = "Subscribe to ECS Task events"
  event_pattern = jsonencode(
    {
      "source" : [
        "aws.ecs"
      ],
      "detail-type" : [
        "ECS Task State Change"
      ]
    }
  )
  tags = merge(
    local.tags,
    {
      Name = var.name
    },
  )
}

resource "aws_cloudwatch_event_target" "default" {
  rule      = aws_cloudwatch_event_rule.default.name
  target_id = "${var.name}-${var.environment}-SendToSQS"
  arn       = module.lambda.lambda_function_arn
}
