# Apres KMS Messaging Terraform module

## Overview

This module will create a KMS Customer Managed Key (CMK) that is intended to support SNS -> SQS communication between encrypted topics and queues. KMS
key aliases names do not need to be globally unique in AWS; however, to match similar resources that must be unique (such as S3 buckets), the
resulting name will have the following pattern|

`account-id`-`environment`-`region`-`name`

where|

* `account-id` is the 12 digit AWS account where the bucket is deployed.
* `environment` is the lower case `environment` variable passed into the terraform stack
* `region` is the AWS region where the bucket is deployed
* `name` is the lower case `name` variable passed into the terraform stack.

For example, if the stack is deployed with|

```hcl
module kms_messaging {
  source = TBD # value depends on your installation
  name = mytestkey
  environment = SystemTest
}
```

and the stack is deployed to the AWS account 12345689012 in us-east-2, the KMS key alias name will
be `123456789012-systemtest-us-east-2-mytestkey-messaging`

### Enforced Best Practices

The following best practices are applied to the topic:

| Id          | Policy                                                                                            |
|-------------|---------------------------------------------------------------------------------------------------|
| CKV_AWS_227 | Ensure KMS key is enabled                                                                         |
| CKV_AWS_33  | Ensure KMS key policy does not contain wildcard (*) principal                                     |
| CKV_AWS_7   | Ensure rotation for customer created CMKs is enabled                                              |
| CKV_AWS_356 | Ensure no IAM policies documents allow * as a statement's resource for restrictable actions       |
| CKV_AWS_358 | Ensure GitHub Actions OIDC trust policies only allows actions from a specific known organization  |
| CKV_AWS_110 | Ensure IAM policies does not allow privilege escalation                                           |
| CKV_AWS_49  | Ensure no IAM policies documents allow * as a statement's actions                                 |
| CKV_AWS_107 | Ensure IAM policies does not allow credentials exposure                                           |
| CKV_AWS_283 | Ensure no IAM policies documents allow ALL or any AWS principal permissions to the resource       |
| CKV_AWS_109 | Ensure IAM policies does not allow permissions management / resource exposure without constraints |
| CKV_AWS_1   | Ensure IAM policies that allow full *-* administrative privileges are not created                 |
| CKV_AWS_108 | Ensure IAM policies does not allow data exfiltration                                              |
| CKV_AWS_111 | Ensure IAM policies does not allow write access without constraints                               |
| CKV_AWS_41  | Ensure no hard coded AWS access key and secret key exists in provider                             |
| CKV2_AWS_64 | Ensure KMS key Policy is defined                                                                  |
| CKV2_AWS_40 | Ensure AWS IAM policy does not allow full IAM privileges                                          |

### Suppressed Best Practices

The following best practices ARE NOT implemented|

| Id | Policy |
|----|--------|

## Example

```hcl
module sns {
  source =../../../modules/
SNS
environment = Dev
name = mytesttopic
}
```

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS| | AccountId}` with the Account ID where this stack is deployed.
- `${AWS| | Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`
- `${encryption_kms_key_id}` with the UUID of the generated customer managed key

```json
[
  {
    Effect
    |
    Allow,
    Action
    |
  [
    kms
    |
    CreateKey,
    kms
    |
    ListAliases
  ],
  Resource
  |
  *
  },
  {
    Effect
    |
    Allow,
    Action
    |
  [
    kms
    |
    EnableKeyRotation,
    kms
    |
    GetKeyRotationStatus,
    kms
    |
    GetKeyPolicy,
    kms
    |
    ListResourceTags,
    kms
    |
    DescribeKey,
    kms
    |
    TagResource
  ],
  Resource
  |
  arn
  |
  aws
  |
  kms
  |
  $
  {
    AWS
    |
    |
    Region
  }
  |
  $
  {
    AWS
    |
    |
    AccountId
  }
  |
  key/$
  {
    encryption_kms_key_id
  }
},
  {
    Effect
    |
    Allow,
    Action
    |
  [
    kms
    |
    CreateAlias
  ],
  Resource
  |
  [
    arn
    |
    aws
    |
    kms
    |
    $
    {
      AWS
      |
      |
      Region
    }
    |
    $
    {
      AWS
      |
      |
      AccountId
    }
    |
    alias/alias/$
    {
      AWS
      |
      |
      AccountId
    }
    -$
    {
      environment
    }
    -$
    {
      AWS
      |
      |
      Region
    }
    -$
    {
      name
    }
    -messaging,
    arn
    |
    aws
    |
    kms
    |
    $
    {
      AWS
      |
      |
      Region
    }
    |
    $
    {
      AWS
      |
      |
      AccountId
    }
    |
    key/$
    {
      encryption_kms_key_id
    }
  ]
},
  {
    Effect
    |
    Allow,
    Action
    |
  [
    kms
    |
    DeleteAlias
  ],
  Resource
  |
  [
    arn
    |
    aws
    |
    kms
    |
    $
    {
      AWS
      |
      |
      Region
    }
    |
    $
    {
      AWS
      |
      |
      AccountId
    }
    |
    alias/alias/$
    {
      environment
    }
    -$
    {
      name
    }
    -messaging,
    arn
    |
    aws
    |
    kms
    |
    $
    {
      AWS
      |
      |
      Region
    }
    |
    $
    {
      AWS
      |
      |
      AccountId
    }
    |
    key/*
  ]
}
]
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                    | Version           |
|-------------------------------------------------------------------------|-------------------|
| <a name=requirement_terraform></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name=requirement_aws></a> [aws](#requirement\_aws)                   | >= 5.0.0          |

## Providers

| Name                                            | Version |
|-------------------------------------------------|---------|
| <a name=provider_aws></a> [aws](#provider\_aws) | 5.60.0  |

## Modules

No modules.

## Resources

| Name                                | Type                                                                                          |
|-------------------------------------|-----------------------------------------------------------------------------------------------|
| [aws_kms_alias.messaging](https     | //registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias)              | resource |
| [aws_kms_key.messaging](https       | //registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)                | resource |
| [aws_kms_key_policy.default](https  | //registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy)         | resource |
| [aws_caller_identity.current](https | //registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)     | data source |
| [aws_iam_policy_document.cmk](https | //registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https          | //registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)              | data source |

## Inputs

| Name | Description | Type | Default |
Required | |------|-------------|------|---------|| --------| | | <a name=input_application></a> [application](#input\_application) | Application
name, used for tagging AWS resources. | `string` | n/a | yes | | <a name=input_component></a> [component](#input\_component) | Component name, used
for tagging AWS resources. | `string` | n/a | yes | | <a name=input_default_tags></a> [default\_tags](#input\_default\_tags) | Default set of tags to
be applied to all resources | `map(string)` | `{}` | no | | <a name=input_environment></a> [environment](#input\_environment) | Environment name, used
for tagging AWS resources, and in the bucket name. | `string` | `dev` | no | | <a name=input_name></a> [name](#input\_name) | Name of the queue, must
be between 3 and 40 characters long and can contain only the following characters| a-z, A-Z, 0-9, \_, and - | `string` | n/a |
yes | | <a name=input_owner></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |

## Outputs

| Name                                                            | Description                                        |
|-----------------------------------------------------------------|----------------------------------------------------|
| <a name=output_cmk_alias></a> [cmk\_alias](#output\_cmk\_alias) | The alias to the messaging key.                    |
| <a name=output_cmk_arn></a> [cmk\_arn](#output\_cmk\_arn)       | The ARN of the KMS customer managed messaging key. |

<!-- END_TF_DOCS -->
