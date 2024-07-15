# Account configuration for Workload Accounts

This module is meant to be applied to every AWS account where you deploy workloads, per region. It sets up
CloudWatch Logs with KMS encryption, and if enabled allows API Gateway to log to CloudWatch Logs.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatchlogs_regional"></a> [cloudwatchlogs\_regional](#module\_cloudwatchlogs\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs_regional | rel/cloudwatchlogs_regional/1.1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_api_gateway_logging"></a> [enable\_api\_gateway\_logging](#input\_enable\_api\_gateway\_logging) | Enable API Gateway logging to CloudWatch Logs. This requires an IAM Role and an API Gateway<br>    configuration per region. By default this is disabled, enable if you are planning to<br>    use API Gateway in the account this is deployed in. | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->