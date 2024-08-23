# Apres DynamoDb SNS Publisher Terraform module

## Overview

This module will create a lambda event source that publishes DynamoDb stream events to an SNS topic table in accordance with best practices. The
lambda function implementation is provided in the https://github.com/apresdev/lambda-ddb-sns-publisher repo.

## Example

```hcl
module "dynamodb_sns_publisher" {
  source = "TBD" # value depends on your installation

  name        = var.name
  environment = "Test"

  # The ARN of the DynamoDb stream
  stream_arn = module.dynamodb.stream_arn

  # The ARN of the SNS topic
  topic_arn = module.sns.topic_arn

}
```

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `${AWS::Region}`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`
- `${lambda_regional_environment}` with the lower case of the variable `var.lambda_regional_environment`

```json
[
  {
    "Effect": "Allow",
    "Action": [
      "sts:GetCallerIdentity",
      "kms:ListAliases",
      "logs:DescribeLogGroups",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingPolicies",
      "sns:GetSubscriptionAttributes",
      "sns:Unsubscribe"
    ],
    "Resource": "*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:DescribeKey"
    ],
    "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/apres/messaging"
  },
  {
    "Effect": "Allow",
    "Action": [
      "ssm:GetParameter"
    ],
    "Resource": "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter//apres/lambda/signing-config-arn"
  },
  {
    "Effect": "Allow",
    "Action": [
      "ssm:GetParameter"
    ],
    "Resource": "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter//apres/lambda/signing-profile-name"
  },
  {
    "Effect": "Allow",
    "Action": [
      "s3:ListBucket",
      "s3:GetBucketWebsite",
      "s3:ListBucketVersions"
    ],
    "Resource": "arn:aws:s3:::${AWS::AccountId}-${lambda_regional_environment}-${AWS::Region}-lambda-artifacts"
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:GetCodeSigningConfig"
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:code-signing-config:*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:DescribeKey"
    ],
    "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/lambda"
  },
  {
    "Effect": "Allow",
    "Action": [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:PassRole",
      "iam:DeleteRolePolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:DeleteRole"
    ],
    "Resource": "arn:aws:iam::${AWS::AccountId}:role/${name}-ddb-sns-publisher-${environment}-LambdaRole"
  },
  {
    "Effect": "Allow",
    "Action": [
      "sqs:CreateQueue",
      "sqs:TagQueue",
      "sqs:GetQueueAttributes",
      "sqs:ListQueueTags",
      "sqs:SetQueueAttributes"
    ],
    "Resource": "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${environment}-${name}-deadletter"
  },
  {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
      "logs:ListTagsForResource",
      "logs:DeleteLogGroup"
    ],
    "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/apres/lambda/${environment}-${name}-ddb-sns-publisher"
  },
  {
    "Effect": "Allow",
    "Action": [
      "sns:Subscribe"
    ],
    "Resource": "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:${environment}-${name}"
  },
  {
    "Effect": "Allow",
    "Action": [
      "iam:PassRole"
    ],
    "Resource": "arn:aws:iam::${AWS::AccountId}:role/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "sqs:CreateQueue",
      "sqs:TagQueue",
      "sqs:GetQueueAttributes",
      "sqs:ListQueueTags",
      "sqs:DeleteQueue"
    ],
    "Resource": "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${environment}-${name}-ddb-sns-publisher-deadletter"
  },
  {
    "Effect": "Allow",
    "Action": [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:DeleteObject"
    ],
    "Resource": "arn:aws:s3:::${AWS::AccountId}-${lambda_regional_environment}-${AWS::Region}-lambda-artifacts/unsigned/${environment}-${name}-ddb-sns-publisher.zip"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:DescribeKey"
    ],
    "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/s3"
  },
  {
    "Effect": "Allow",
    "Action": [
      "signer:StartSigningJob"
    ],
    "Resource": "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-profiles/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "signer:DescribeSigningJob"
    ],
    "Resource": "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-jobs/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:CreateFunction",
      "lambda:GetFunction",
      "lambda:ListVersionsByFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:DeleteFunction"
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:${environment}-${name}-ddb-sns-publisher"
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:GetEventSourceMapping",
      "lambda:DeleteEventSourceMapping"
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:event-source-mapping:*"
  }
]
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                      | Version           |
|---------------------------------------------------------------------------|-------------------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 5.0.0          |

## Providers

| Name                                                             | Version |
|------------------------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws)                | 5.64.0  |
| <a name="provider_external"></a> [external](#provider\_external) | n/a     |
| <a name="provider_github"></a> [github](#provider\_github)       | 6.2.3   |

## Modules

| Name                                                   | Source                                                          | Version          |
|--------------------------------------------------------|-----------------------------------------------------------------|------------------|
| <a name="module_lambda"></a> [lambda](#module\_lambda) | git@github.com:apresdev/apres-terraform.git//modules/aws/lambda | rel/lambda/0.2.0 |

## Resources

| Name                                                                                                                                               | Type        |
|----------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_iam_role_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                         | resource    |
| [aws_lambda_event_source_mapping.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                      | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)              | data source |
| [aws_kms_alias.messaging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias)                                | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                        | data source |
| [external_external.artifact_download](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external)                | data source |
| [github_release.lambda](https://registry.terraform.io/providers/hashicorp/github/latest/docs/data-sources/release)                                 | data source |

## Inputs

| Name                                                                                                                    | Description                                                                            | Type          | Default            | Required |
|-------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|---------------|--------------------|:--------:|
| <a name="input_application"></a> [application](#input\_application)                                                     | Application name, used for tagging AWS resources.                                      | `string`      | n/a                |   yes    |
| <a name="input_component"></a> [component](#input\_component)                                                           | Component name, used for tagging AWS resources.                                        | `string`      | n/a                |   yes    |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags)                                                | Default set of tags to be applied to all resources                                     | `map(string)` | `{}`               |    no    |
| <a name="input_environment"></a> [environment](#input\_environment)                                                     | Environment name, used for tagging AWS resources, and in the bucket name.              | `string`      | `"dev"`            |    no    |
| <a name="input_lambda_regional_environment"></a> [lambda\_regional\_environment](#input\_lambda\_regional\_environment) | Lambda Regional Environment Name, used to lookup regional code signing and S3 buckets. | `string`      | `"WorkLoadConfig"` |    no    |
| <a name="input_name"></a> [name](#input\_name)                                                                          | The name used to generate the SNS publisher resources (i.e. the lambda naming).        | `string`      | n/a                |   yes    |
| <a name="input_owner"></a> [owner](#input\_owner)                                                                       | Owner of the resources, used for tagging AWS resources.                                | `string`      | n/a                |   yes    |
| <a name="input_stream_arn"></a> [stream\_arn](#input\_stream\_arn)                                                      | The ARN of the DynamoDB stream acting as the event source.                             | `string`      | n/a                |   yes    |
| <a name="input_topic_arn"></a> [topic\_arn](#input\_topic\_arn)                                                         | The ARN of the SNS topic acting as the event sink.                                     | `string`      | n/a                |   yes    |

## Outputs

| Name                                                                                | Description |
|-------------------------------------------------------------------------------------|-------------|
| <a name="output_binary_path"></a> [binary\_path](#output\_binary\_path)             | n/a         |
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn)                | n/a         |
| <a name="output_lambda_artifact"></a> [lambda\_artifact](#output\_lambda\_artifact) | n/a         |

<!-- END_TF_DOCS -->
