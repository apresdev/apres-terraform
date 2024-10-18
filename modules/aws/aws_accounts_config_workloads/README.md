# Account configuration for Workload Accounts

This module is meant to be applied to every AWS account where you deploy workloads, per region. It sets up
the following:
* CloudWatch Logs with KMS encryption
* If enabled, allows API Gateway to log to CloudWatch Logs.
* Creates an S3 bucket for Load Balancer access logs, by default keeping access logs for 365 days. The bucket
  name will be `<account-id>-workloadconfig-<region>-load-balancer-logs`.
* Adds the ECS event lifecyle to monitor for ECS tasks that are in a crash loop.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Replace `${AWS::AccountID}` with the AWS Account ID where this is deployed, and `${AWS::Region}`
with the region where this is deployed.

In addition to the permissions below, the permissions of the [ecs_events](../ecs_events/README.md) will
also need to be applied!

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
},
{
  "Sid": "AllowManageAPIGWAccountSettings",
  "Effect": "Allow",
  "Action": [
    "apigateway:*"
  ],
  "Resource": "arn:aws:apigateway:${AWS::Region}::/account"
},
{
  "Sid": "AllowManageS3LoadBalancerBucket",
  "Effect": "Allow",
  "Action": [
    "s3:*"
  ],
  "Resource": "arn:aws:s3:::*-load-balancer-logs"
},
{
  "Sid": "DenyS3Delete",
  "Effect": "Deny",
  "Action": [
    "s3:Delete*"
  ],
  "Resource": "arn:aws:s3:::*-load-balancer-logs"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.69.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatchlogs_regional"></a> [cloudwatchlogs\_regional](#module\_cloudwatchlogs\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs_regional | rel/cloudwatchlogs_regional/1.2.0 |
| <a name="module_ecs_events"></a> [ecs\_events](#module\_ecs\_events) | git@github.com:apresdev/apres-terraform.git//modules/aws/ecs_events | rel/ecs_events/0.1.0 |
| <a name="module_lambda_regional"></a> [lambda\_regional](#module\_lambda\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/lambda_regional | rel/lambda_regional/0.2.4 |
| <a name="module_load_balancer_logs_bucket"></a> [load\_balancer\_logs\_bucket](#module\_load\_balancer\_logs\_bucket) | git@github.com:apresdev/apres-terraform.git//modules/aws/s3 | rel/s3/3.0.1 |
| <a name="module_messaging_regional"></a> [messaging\_regional](#module\_messaging\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/messaging_regional | rel/messaging_regional/0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.nlb_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.post2022_lb_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.pre2022_lb_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_api_gateway_logging"></a> [enable\_api\_gateway\_logging](#input\_enable\_api\_gateway\_logging) | Enable API Gateway logging to CloudWatch Logs. This requires an IAM Role and an API Gateway<br>    configuration per region. By default this is disabled, enable if you are planning to<br>    use API Gateway in the account this is deployed in. | `bool` | `false` | no |
| <a name="input_retain_load_balancer_logs_days"></a> [retain\_load\_balancer\_logs\_days](#input\_retain\_load\_balancer\_logs\_days) | Number of days to retain the load balancer logs in the S3 bucket. By default, this is set to 365.<br>    Setting this to -1 will retain logs indefinitely. | `number` | `365` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->