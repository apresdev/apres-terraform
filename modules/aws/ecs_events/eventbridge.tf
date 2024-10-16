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

# resource "aws_sqs_queue" "default" {
#   name = var.name
#   tags = merge(
#     local.tags,
#     {
#       Name = var.name
#     },
#   )
# }

# resource "aws_sqs_queue_policy" "default" {
#   queue_url = aws_sqs_queue.default.url
#   policy    = data.aws_iam_policy_document.default.json
# }

# data "aws_iam_policy_document" "default" {
#   statement {
#     sid    = "AllowEventBridgeToSendToSQS"
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["events.amazonaws.com"]
#     }
#     actions   = ["sqs:SendMessage"]
#     resources = [aws_sqs_queue.default.arn]

#     condition {
#       test     = "ArnEquals"
#       variable = "aws:SourceArn"
#       values   = [aws_cloudwatch_event_rule.default.arn]
#     }
#   }
# }

# {
#   "Version": "2012-10-17",
#   "Id": "Policy1729030886960",
#   "Statement": [
#     {
#       "Sid": "Stmt1729030883605",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "events.amazonaws.com"
#       },
#       "Action": "sqs:SendMessage",
#       "Resource": "arn:aws:sqs:us-east-2:533267011653:goodbyeworld",
#       "Condition": {
#         "ArnEquals": {
#           "aws:SourceArn": "arn:aws:events:us-east-2:533267011653:rule/goodbyeworld20241015215437310900000001"
#         }
#       }
#     }
#   ]
# }