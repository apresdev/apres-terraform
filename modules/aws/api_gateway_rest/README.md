# Rest API Gateway

Creates a REST API Gateway.

This depends on the [aws_accounts_config_workloads](../aws_accounts_config_workloads/) module to be deployed first, with
the `var.enable_api_gateway_logging` variable set to true.

API Gateway logging will be send to CloudWatch Logs, to Log Group made by the variables:
`/${var.application}-${var.component}/${var.name}-${var.environment}-apigateway`

WAF is not included in this module. We highly recommend that a WAF is included. Example code for using both this API Gateway
and a WAF is as follows:
```hcl
module "apigateway" {
  # Version here for documentation only, may not be the latest.
  source                 = "git@github.com:apresdev/apres-terraform.git//modules/aws/api_gateway_rest?ref=rel/api_gateway_rest/1.0.0"
  # truncated for brevity...
  api_version            = "v1"
  openapi_spec_file_path = "openapi.yaml"
}

module "waf" {
  # Version here for documentation only, may not be the latest.
  source                 = "git@github.com:apresdev/apres-terraform.git//modules/aws/waf?ref=rel/waf/1.0.0"
  # truncated for brevity...
  associate_resource_arn = module.apigateway.apigw_arn
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.59.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cwl_apigateway"></a> [cwl\_apigateway](#module\_cwl\_apigateway) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs | rel/cloudwatchlogs/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_deployment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_method_settings.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_vpc_link.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_version"></a> [api\_version](#input\_api\_version) | The version of the API, for example v1, used for the stage name and will be the first part of the API path, but is not passed along to the container. | `string` | `"v1"` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_load_balancer_arn"></a> [load\_balancer\_arn](#input\_load\_balancer\_arn) | The ARN of a target load balancer to which the API Gateway should be forwarding requests, as defined<br>    in the API spec. If this is set, a VPC Link will be created.<br><br>    Because the VPC Link ID is not known until after it is built, when the OpenAPI spec is processed, the<br>    variable `vpc_link_connection_id` will be substituted in with the actual VPC Link ID. An example of how<br>    to configure this in your OpenAPI Spec is:<pre>"x-amazon-apigateway-integration": {<br>          "connectionId": "${vpc_link_connection_id}",<br>          "connectionType": "VPC_LINK",<br>          "httpMethod": "any",<br>          "type": "http_proxy",<br>          "uri": "https://${nlb_uri}/blah",</pre>In this example the `nlb_uri` is set to DNS name of the load balancer handling the requests,<br>    not created in this module, and must be passed into the<br>    `openapi_spec_variables` variable. For example:<pre>resource "aws_lb" "my_loadbalancer" {<br>      ...<br>    }<br>    module "api_gateway_rest" {<br>      ...<br>      load_balancer_arn = aws_lb.my_loadbalancer.arn        # causes VPC Link to be created<br>      openapi_spec_variables = {<br>        nlb_uri = aws_lb_listener.my_loadbalancer.dns_name  # Used in the OpenAPI spec<br>      }<br>    }</pre> | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_openapi_spec_file_path"></a> [openapi\_spec\_file\_path](#input\_openapi\_spec\_file\_path) | The path to the OpenAPI spec file to use for the API Gateway. | `string` | n/a | yes |
| <a name="input_openapi_spec_variables"></a> [openapi\_spec\_variables](#input\_openapi\_spec\_variables) | Values to be substituted into the OpenAPI spec, that are only known at deploy time. This module<br>    uses the [templatefile](https://developer.hashicorp.com/terraform/language/functions/templatefile) function<br>    to substitute variables.<br><br>    For example, to include an Amazon integration, your OpenAPI spec might look like:<pre>x-amazon-apigateway-integration:<br>        connectionId: "${vpc_link_connection_id}"<br>        connectionType: "VPC_LINK"<br>        httpMethod: "${http_method}"<br>        type: "http_proxy"<br>        uri: "${nlb_uri}"<br>        payloadFormatVersion: "1.0"</pre>and then the variables passed in here would include:<pre>module "api_gateway_rest" {<br>      ...<br>      openapi_spec_variables = {<br>        http_method = "ANY"<br>        nlb_uri = "https://${aws_lb_listener.my_loadbalancer.dns_name}/"<br>      }<br>    }</pre>See the `load_balancer_arn` variable for details on the `vpc_link_connection_id` substitution. | `map(string)` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apigw_arn"></a> [apigw\_arn](#output\_apigw\_arn) | The ARN of the API Gateway REST API |
| <a name="output_apigw_execution_arn"></a> [apigw\_execution\_arn](#output\_apigw\_execution\_arn) | The Execution ARN of the API Gateway REST API, used in Lambda permissions. |
| <a name="output_apigw_id"></a> [apigw\_id](#output\_apigw\_id) | The ID of the API Gateway REST API |
| <a name="output_apigw_root_resource_id"></a> [apigw\_root\_resource\_id](#output\_apigw\_root\_resource\_id) | The Root Resource ID of the API Gateway REST API |
| <a name="output_apigw_stage_arn"></a> [apigw\_stage\_arn](#output\_apigw\_stage\_arn) | The ARN of the API Gateway REST API Stage |
| <a name="output_apigw_stage_execution_arn"></a> [apigw\_stage\_execution\_arn](#output\_apigw\_stage\_execution\_arn) | The Execution ARN of the API Gateway REST API Stage, used in Lambda permissions. |
| <a name="output_apigw_stage_id"></a> [apigw\_stage\_id](#output\_apigw\_stage\_id) | The ID of the API Gateway REST API Stage |
| <a name="output_apigw_stage_invoke_url"></a> [apigw\_stage\_invoke\_url](#output\_apigw\_stage\_invoke\_url) | The URL to invoke the API via the stage |
<!-- END_TF_DOCS -->