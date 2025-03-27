# Creates the lambda function.
#
# The following best practices are always applied:
# - CKV_AWS_50: "X-Ray tracing is enabled for Lambda"
# - CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
# - CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
# - CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
# - CKV_AWS_45: "Ensure no hard-coded secrets exist in lambda environment"
#
# The following best practices are applied, if configured:
# - CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
# - CKV_AWS_115:"Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
#

resource "aws_lambda_function" "default" {
  function_name = local.name
  role          = aws_iam_role.default.arn
  description   = var.description

  architectures = var.architectures
  handler       = coalesce(var.handler, basename(local.artifact))
  memory_size   = var.memory_size
  runtime       = var.runtime
  timeout       = var.timeout

  ephemeral_storage {
    size = var.ephemeral_storage
  }

  #checkov:skip=CKV_AWS_115:"Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # This is only enabled if the client chooses to attach the VPC, by default we explicitly do not add it. As it slows down deployment times and
  # it violates the principle of least privileges to always connect the lambda to the VPC.
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  dynamic "vpc_config" {
    for_each = local.use_vpc ? [1] : []
    content {
      subnet_ids         = data.aws_subnets.private[0].ids
      security_group_ids = [aws_security_group.default[0].id]
    }
  }
  # If VPC configuration is applied, it normally takes ~5 minutes to delete the security group, but
  # occasionally can take up to 60 minutes. The aws_lambda_function resource has a
  # replace_security_groups_on_destroy property, that in theory speeds up destruction,
  # but in practice does not, plus it leaves ENI's around in the VPC forever, no longer marked
  # for cleanup. So we explicitly set it to null, in case a future developer stumbles on it.
  replace_security_groups_on_destroy = null

  # CKV_AWS_50: "X-Ray tracing is enabled for Lambda"
  tracing_config {
    mode = "PassThrough"
  }

  # CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  dead_letter_config {
    target_arn = aws_sqs_queue.deadletter.arn
  }

  # CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  kms_key_arn = data.aws_kms_alias.lambda_artifacts.target_key_arn

  # CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  code_signing_config_arn = var.disable_code_signing ? "" : data.aws_ssm_parameter.signing_config_arn[0].value
  s3_bucket               = var.disable_code_signing ? local.artifact_bucket : aws_signer_signing_job.default[0].signed_object[0].s3[0].bucket
  s3_key                  = var.disable_code_signing ? local.artifact_key : aws_signer_signing_job.default[0].signed_object[0].s3[0].key

  # CKV_AWS_45: "Ensure no hard-coded secrets exist in lambda environment"
  environment {
    variables = merge({
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id,
      ENVIRONMENT    = var.environment,
      APPLICATION    = var.application,
      COMPONENT      = var.component,
      },
      var.environment_variables
    )
  }

  logging_config {
    log_format = "JSON"
    log_group  = local.log_group
  }

  tags = merge(
    local.tags,
    tomap({
      Name = local.name
    })
  )

  depends_on = [
    data.aws_kms_alias.lambda_artifacts,
    aws_signer_signing_job.default,
    aws_iam_role.default,
    aws_iam_role_policy.default,
    module.cloudwatch_log,
  ]
}