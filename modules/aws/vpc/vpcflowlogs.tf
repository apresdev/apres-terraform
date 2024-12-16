locals {
  cloudwatch_log_group_name = "/apres/${var.environment}-VPCFlowLogs"
}
# The following sets up VPC Flow Logs to CLoudWatch Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  #checkov:skip=CKV_AWS_338:Flow Log Retention is set by the user.
  #checkov:skip=CKV_AWS_158:Flow Logs encrypted by default KMS key is acceptable.
  name = local.cloudwatch_log_group_name
  tags = merge(
    local.tags,
    {
      Name = format("%s VPC Flow Logs", var.environment),
    },
  )
  retention_in_days = var.vpc_flow_log_retention_days
}

resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = var.vpc_flow_log_traffic_type
  vpc_id          = aws_vpc.vpc.id
  tags = merge(
    local.tags,
    {
      Name = format("%s VPC Flow Logs", var.environment),
    },
  )
}

data "aws_iam_policy_document" "vpc_flow_logs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "vpc_flow_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"]
  }
}

resource "aws_iam_policy" "vpc_flow_logs" {
  name_prefix = "${var.environment}-vpcflowlogs-"
  policy      = data.aws_iam_policy_document.vpc_flow_logs.json
  tags = merge(
    local.tags,
    {
      Name = format("%s VPC Flow Logs", var.environment),
    },
  )
}

resource "aws_iam_role" "vpc_flow_logs" {
  name_prefix        = "${var.environment}-vpcflowlogs-"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume_role.json
  tags = merge(
    local.tags,
    {
      Name = format("%s VPC Flow Logs", var.environment),
    },
  )
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  role       = aws_iam_role.vpc_flow_logs.name
  policy_arn = aws_iam_policy.vpc_flow_logs.arn
}