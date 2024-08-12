# Regional Messaging module

Sets up and configures regional resources for messaging services (i.e. SNS, SQS, etc.). This is meant to be
deployed once per AWS account and region.


Resources created include:
* A KMS key, to be used for encrypting messages in services such as SNS, SQS, etc.
* An alias /aws/apres/messaging to be consumed by the apres/sns and apres/sqs modules
* Appropriate key policy for SNS to use the key.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`
- `${encryption_kms_key_id}` with the UUID of the generated customer managed key

```json

[
  {
    "Effect": "Allow",
    "Action": [
      "kms:CreateKey",
      "kms:ListAliases"
    ],
    "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:EnableKeyRotation",
      "kms:GetKeyRotationStatus",
      "kms:GetKeyPolicy",
      "kms:ListResourceTags",
      "kms:DescribeKey",
      "kms:TagResource",
      "kms:ScheduleKeyDeletion"
    ],
    "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:CreateAlias",
      "kms:UpdateAlias",
      "kms:DeleteAlias"
    ],
    "Resource": [
      "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:alias/alias/messaging",
      "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/*"
    ]
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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.messaging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.messaging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cmk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | `"Messaging"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | `"Messaging"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | `"Dev"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cmk_alias"></a> [cmk\_alias](#output\_cmk\_alias) | The alias to the messaging key. |
| <a name="output_cmk_arn"></a> [cmk\_arn](#output\_cmk\_arn) | The ARN of the KMS customer managed messaging key. |
<!-- END_TF_DOCS -->
