# CloudWatch Logs Group

Sets up and configures regional resources for CloudWatch Logs (CWL). This is meant to be
deployed once per AWS account and region.

API Gateway logging to CloudWatch Logs is also included here, since it follows the same requirement
to configure a single item per account/region. That can be disabled by setting the `enable_api_gateway_logging`
to false. The configuration consists of a role per region, and setting the API Gateway Logging setting to use
the role. See [Set up CloudWatch logging for REST APIs in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html) for details.

Resources created include:
* A KMS key, to be used for encrypting CloudWatch Log Groups
* An alias /aws/apres/cloudwatchlogs to be consumed by the apres/cloudwatchlogs module
* Appropriate key policy for CWL to use the key.
* A role for API Gateway
* The API Gateway account setting to use the role.

Future considerations:
* A subscription to move CWL to S3 or OpenSearch automatically.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON. Replace
`${AWS::AccountId}` with the current account id.

```json
{
  "Effect": "Allow",
  "Action": [
    "apigateway:UpdateAccount",
    "cloudwatch:*",
    "kms:*",
    "logs:*"
  ],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": [
    "iam:*"
  ],
  "Resource": "arn:aws:iam::${AWS::AccountID}:role/ApresAPIGatewayCloudWatchLogsRole*"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_iam_role.apigw_cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_alias.cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.apigw_cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | `"CloudWatchLogs"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | `"CloudWatchLogs"` | no |
| <a name="input_enable_api_gateway_logging"></a> [enable\_api\_gateway\_logging](#input\_enable\_api\_gateway\_logging) | Enable API Gateway logging to CloudWatch Logs. This requires an IAM Role and an API Gateway<br>    configuration per region. By default this is enabled. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_cloudwatch_logs_role_arn"></a> [api\_gateway\_cloudwatch\_logs\_role\_arn](#output\_api\_gateway\_cloudwatch\_logs\_role\_arn) | n/a |
| <a name="output_kms_alias"></a> [kms\_alias](#output\_kms\_alias) | The ARN of the KMS alias used to encrypt the CloudWatch Log Group |
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | The ARN of the KMS key used to encrypt the CloudWatch Log Group |
<!-- END_TF_DOCS -->