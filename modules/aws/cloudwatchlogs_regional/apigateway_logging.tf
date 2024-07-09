# Setup CloudWatch Logs permission for API Gateway
resource "aws_iam_role" "apigw_cwl" {
  count = var.enable_api_gateway_logging ? 1 : 0
  name                = "ApresAPIGatewayCloudWatchLogsRole-${data.aws_region.current.name}"
  assume_role_policy  = data.aws_iam_policy_document.apigw_cwl[0].json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
}

data "aws_iam_policy_document" "apigw_cwl" {
  count = var.enable_api_gateway_logging ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_api_gateway_account" "default" {
  count = var.enable_api_gateway_logging ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw_cwl[0].arn
}