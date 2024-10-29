# This allows lambda to assume the IAM role.
data "aws_iam_policy_document" "assume_role" {

  # Allows the lambda to assume the IAM role
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

}

# Creates the role needed by the lambda function.
resource "aws_iam_role" "default" {
  name_prefix        = "${local.name}-LambdaRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    local.tags,
    tomap({
      Name = local.name
    })
  )
}

# This grants the permissions the lambda needs during execution
data "aws_iam_policy_document" "default" {

  # Allows the lambda to write to cloud watch logs
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      module.cloudwatch_log.cwl_arn,
      "${module.cloudwatch_log.cwl_arn}:*"
    ]
  }

  # Give the lambda function permission to send messages to the DLQ
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.deadletter.arn
    ]
  }

  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  # This gives Lambda the permissions to attach the function to the VPC
  statement {
    sid    = "AWSLambdaVPCAccessExecutionPermissions"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    # Unfortunately, according to the docs, you need to use "*".
    # TODO: See if we can minimize the scope at little to at least the region and account
    resources = ["*"]
  }

  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  # This gives Lambda the permissions to attach the function to the VPC
  statement {
    sid    = "AWSLambdaSecurityGroupAccessExecutionPermissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
    ]
    # Unfortunately, according to the docs, you need to use "*"
    resources = ["*"]
  }

  # Security Best Practice, see: https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html
  # Prevent the lambda function itself from performing any of the above granted permissions
  statement {
    effect = "Deny"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "lambda:SourceFunctionArn"
      values = [
        "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.name}"
      ]
    }
  }
}

# Attaches the default lambda permissions to the policy
resource "aws_iam_role_policy" "default" {
  name_prefix = "${local.name}-LambdaPolicy"
  role        = aws_iam_role.default.name
  policy      = data.aws_iam_policy_document.default.json
}
