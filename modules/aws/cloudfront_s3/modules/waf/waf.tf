locals {
  tags = {
    "application" = var.application
    "component"   = var.component
    "owner"       = var.owner
    "environment" = var.environment
    "managed-by"  = "Terraform"
  }
}

module "cloudwatchlogs" {
  #checkov:skip=CKV_TF_1: No hash specified, that's ok because we are using the version.
  source = "git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs?ref=rel/cloudwatchlogs/1.1.0"
  # The name MUST be prepended with "aws-waf-logs-" for the WAF to be able to log to it.
  name              = "aws-waf-logs-${lower(var.name)}-${lower(var.environment)}"
  path              = "aws-waf-logs-${lower(var.name)}-${lower(var.environment)}"
  application       = var.application
  component         = var.component
  environment       = var.environment
  owner             = var.owner
  retention_in_days = 365
}

resource "aws_wafv2_web_acl_logging_configuration" "default" {
  log_destination_configs = [module.cloudwatchlogs.cwl_arn]
  resource_arn            = aws_wafv2_web_acl.default.arn
}

resource "aws_cloudwatch_log_resource_policy" "default" {
  policy_document = data.aws_iam_policy_document.default.json
  policy_name     = "webacl-policy-${lower(var.name)}-${lower(var.environment)}}"
}

data "aws_iam_policy_document" "default" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${module.cloudwatchlogs.cwl_arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}

resource "aws_wafv2_web_acl" "default" {
  #checkov:skip=CKV_AWS_192:False positive, the AWSManagedRulesKnownBadInputsRuleSet is here for log4j mitigation.
  name        = "${lower(var.name)}-${lower(var.environment)}-web-acl"
  description = "${title(var.name)} Web ACL"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${lower(var.name)}-${lower(var.environment)}-web-acl"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${lower(var.name)}-${lower(var.environment)}-waf-awscommonruleset"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${lower(var.name)}-${lower(var.environment)}-waf-awsknownbadinputsrule"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 3

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    override_action {
      count {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${lower(var.name)}-${lower(var.environment)}-waf-awsanonymousiplist"
      sampled_requests_enabled   = false
    }
  }

  tags = merge(
    local.tags,
    tomap({
      Name = var.name
    })
  )
}