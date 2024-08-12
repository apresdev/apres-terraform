# Apres DynamoDb Terraform module

## Overview

This module will create an SNS topic in accordance with best practices. SNS topic names do not need to be globally unique in AWS; however, to match
similar resources that must be unique (such as S3 buckets), the resulting name will have the following pattern:

`account-id`-`environment`-`region`-`name`

where:

* `account-id` is the 12 digit AWS account where the bucket is deployed.
* `environment` is the lower case `environment` variable passed into the terraform stack
* `region` is the AWS region where the bucket is deployed
* `name` is the lower case `name` variable passed into the terraform stack.

For example, if the stack is deployed with:

```hcl
module "sns_sqs_subscriber" {
  source      = "TBD" # value depends on your installation
  name        = "mytesttopic"
  environment = "SystemTest"
}
```

and the stack is deployed to the AWS account 12345689012 in us-east-2, the SNS topic name will be `123456789012-systemtest-us-east-2-mytesttopic`

### Enforced Best Practices

The following best practices are applied to the topic:

| Id          | Policy                                                                                               |
|-------------|------------------------------------------------------------------------------------------------------|

### Suppressed Best Practices

The following best practices ARE NOT implemented:

| Id | Policy |
|----|--------|

## Example

```hcl
module "sns_sqs_subscriber" {
  source      = "../../../modules/sns_sqs_subscriber"
  environment = "Dev"
  sns_topic_arn = "mytesttopic"
  sqs_queue_arn = "mytesttopic"
  sqs_queue_url = "mytesttopic"
}
```

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`
- `${encryption_kms_key_id}` with the lower case of the variable `var.encryption_kms_key_id` (if specified)

```json
[
]
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic_subscription.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | `"dev"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_raw_message_delivery"></a> [raw\_message\_delivery](#input\_raw\_message\_delivery) | (Optional) Whether to enable raw message delivery (the original message is directly passed, not wrapped in JSON with the original message in the message property). Default is true. | `bool` | `true` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The AWS ARN of the SNS topic to subscribe to. | `string` | n/a | yes |
| <a name="input_sqs_queue_arn"></a> [sqs\_queue\_arn](#input\_sqs\_queue\_arn) | The AWS ARN of the SQS subscriber queue. | `string` | n/a | yes |
| <a name="input_sqs_queue_url"></a> [sqs\_queue\_url](#input\_sqs\_queue\_url) | The URL of the SQS subscriber queue. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subscription_name"></a> [subscription\_name](#output\_subscription\_name) | The ARN of the subcription. |
<!-- END_TF_DOCS -->
