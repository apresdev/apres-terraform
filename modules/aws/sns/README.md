# Apres SNS Terraform module

## Overview

This module will create an SNS topic in accordance with best practices. SNS topic names do not need to be globally unique in AWS; as such, the
resulting name will have the following pattern:

`environment`-`name`

where:

* `environment` is the lower case `environment` variable passed into the terraform stack
* `name` is the lower case `name` variable passed into the terraform stack.

For example, if the stack is deployed with:

```hcl
module "sns" {
  source      = "TBD" # value depends on your installation
  name        = "mytesttopic"
  environment = "SystemTest"
}
```

the SNS topic name will be `SystemTest-mytesttopic`

### Enforced Best Practices

The following best practices are applied to the topic:

| Id          | Policy                                                                                               |
|-------------|------------------------------------------------------------------------------------------------------|
| CKV_AWS_26  | Ensure all data stored in the SNS topic is encrypted.                                                |
| CKV_AWS_169 | Ensure SNS topic policy is not public by only allowing specific services or principals to access it. |

### Suppressed Best Practices

The following best practices ARE NOT implemented:

| Id | Policy |
|----|--------|

## Example

```hcl
module "sns" {
  source      = "../../../modules/SNS"
  environment = "Dev"
  name        = "mytesttopic"
}
```

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`

```json
[
  {
    "Effect": "Allow",
    "Action": [
      "sns:CreateTopic",
      "sns:SetTopicAttributes",
      "sns:GetTopicAttributes",
      "sns:ListTagsForResource",
      "sns:DeleteTopic"
    ],
    "Resource": "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:${environment}-${name}"
  }
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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.sns-topic-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | The human-readable name used in the From field for notifications to email and email-json endpoints | `string` | n/a | yes |
| <a name="input_encryption_kms_key_id"></a> [encryption\_kms\_key\_id](#input\_encryption\_kms\_key\_id) | The ARN of the KMS key to use for server-side encryption. <br/>  If not provided, the default customer managed key 'alias/apres/messaging' will be used. | `string` | `"alias/apres/messaging"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | `"dev"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the queue, must be between 3 and 40 characters long and can contain only the following characters: a-z, A-Z, 0-9, \_, and - | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_policy"></a> [policy](#input\_policy) | (Optional) The JSON policy for the SQS queue. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_topic_arn"></a> [topic\_arn](#output\_topic\_arn) | The ARN of the SNS topic. |
| <a name="output_topic_name"></a> [topic\_name](#output\_topic\_name) | The name of the SNS topic. |
<!-- END_TF_DOCS -->
