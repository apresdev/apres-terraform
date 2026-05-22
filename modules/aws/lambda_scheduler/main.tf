locals {
  tags = merge(
    var.extra_tags,
    tomap({
      "application" = var.application
      "component"   = var.component
      "owner"       = var.owner
      "environment" = var.environment
      "managed-by"  = "Terraform"
    })
  )
}

module "apres_names" {
  #checkov:skip=CKV_TF_1:False positive, we are not using a hash because we use the tagged version.
  source      = "git::https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names?ref=rel/apres_names/2.0.1"
  name        = var.name
  environment = var.environment
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = module.apres_names.local_name
  description         = "Schedule for Lambda Function ${module.apres_names.local_name}"
  schedule_expression = var.schedule_expression
  tags = merge(
    local.tags,
    tomap({
      Name = module.apres_names.local_name
    })
  )
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = var.lambda_arn
}

resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}