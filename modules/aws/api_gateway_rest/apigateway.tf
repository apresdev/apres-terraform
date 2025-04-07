resource "aws_api_gateway_rest_api" "default" {
  name        = local.name
  description = "${local.name} REST API"
  # Merge changes instead of replace, see note at the top of
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api#openapi-specification
  put_rest_api_mode = "merge"
  body = templatefile(var.openapi_spec_file_path,
    merge(
      var.openapi_spec_variables,
      {
        vpc_link_connection_id = var.attach_vpc_load_balancer ? aws_api_gateway_vpc_link.default[0].id : ""
      }
    )
  )

  lifecycle {
    create_before_destroy = true
  }

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

# TODO: I think stages needs some work but not entirely sure how that works yet.
# TODO: Look at the canary settings for deployment
# TODO: Look at cache sizes. This costs $ to deploy.
resource "aws_api_gateway_stage" "default" {
  #checkov:skip=CKV2_AWS_51: Not using client certificate authentication for now.
  #checkov:skip=CKV2_AWS_29: True, the user should specify their own WAF.
  #checkov:skip=CKV_AWS_120: Turning caching off for now, will address later
  deployment_id = aws_api_gateway_deployment.default.id
  rest_api_id   = aws_api_gateway_rest_api.default.id
  stage_name    = var.api_version

  access_log_settings {
    destination_arn = module.cwl_apigateway.cwl_arn
    # Format is a single line string. See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
    format = "{ \"requestId\":\"$context.requestId\", \"extendedRequestId\":\"$context.extendedRequestId\", \"ip\": \"$context.identity.sourceIp\", \"caller\":\"$context.identity.caller\", \"user\":\"$context.identity.user\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\", \"resourcePath\":\"$context.resourcePath\", \"status\":\"$context.status\", \"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
  }

  # this is recommended by checkov but not sure what the impact is.
  cache_cluster_enabled = false

  # recommended by checkov, not sure how it works. May be more valuable with Lambda's that have xray tracing enabled.
  xray_tracing_enabled = true

  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

resource "aws_api_gateway_deployment" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  lifecycle {
    create_before_destroy = true
  }

  # Trigger redeployment when the OpenAPI spec changes.
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.default.body))
  }
}

resource "aws_api_gateway_vpc_link" "default" {
  count       = var.attach_vpc_load_balancer ? 1 : 0
  name        = local.name
  target_arns = [var.load_balancer_arn]
  tags = merge(
    local.tags,
    {
      Name = local.name
    },
  )
}

# TODO: Look at caching
resource "aws_api_gateway_method_settings" "default" {
  #checkov:skip=CKV2_AWS_51: Not using client certificate authentication for now.
  #checkov:skip=CKV_AWS_225: Not enabling cache for now
  #checkov:skip=CKV_AWS_308: Not enabling cache for now, so no encryption needed
  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name  = aws_api_gateway_stage.default.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    caching_enabled    = false
    data_trace_enabled = false # TODO: is this useful?
  }
}

resource "aws_api_gateway_domain_name" "default" {
  count                    = local.do_route53 ? 1 : 0
  domain_name              = var.domain_name
  regional_certificate_arn = var.acm_certificate_arn == "" ? module.acm_certificate[0].certificate_arn : var.acm_certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  security_policy = "TLS_1_2"
}

resource "aws_api_gateway_base_path_mapping" "default" {
  count       = local.do_route53 ? 1 : 0
  api_id      = aws_api_gateway_rest_api.default.id
  domain_name = aws_api_gateway_domain_name.default[0].domain_name
  stage_name  = aws_api_gateway_stage.default.stage_name
  base_path   = var.base_path_mapping
}

