# ECS Events

This module sets up services to detect when an ECS task is in a crash loop.

It sets up the following services:
* EventBridge rule which subscribes to ECS Task State Changes
* Lambda which is triggered by the EventBridge rule, and emits a CloudWatch Metric

The metric is the namespace `Apres/ECS`, has the name `TaskNonZeroExitCode` and the following dimensions:
* Cluster: Name of the ECS cluster
* Service: Name of the ECS service
* Task: Name of the ECS Task

The metric shows the number of tasks that have exited with a non-zero exit code for the period of time.

This module is not meant to be deployed by itself, it should be part of the `aws_accounts_config_workloads` module,
but is kept separate for simpler development and testing.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute the following variables:
* `${AWS::AccountId}` with the Account ID where this is deployed
* `${AWS::Region}` with the region such as `us-east-2`
* `${Name}` with the name passed in as a variable
* `${Environment}` with the environment passed in as a variable

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter//apres/lambda/signing-config-arn",
                "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter//apres/lambda/signing-profile-name"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketWebsite",
                "s3:ListBucketVersions"
            ],
            "Resource": "arn:aws:s3:::${AWS::AccountId}-workloadconfig-${AWS::Region}-lambda-artifacts"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:DescribeKey"
            ],
            "Resource": [
                "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/lambda",
                "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/s3"
            ]
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
                "iam:*"
            ],
            "Resource": "arn:aws:iam::${AWS::AccountId}:role/${Name}-${Environment}-LambdaRole"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/apres/lambda/${Environment}-${Name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "events:*"
            ],
            "Resource": "arn:aws:events:${AWS::Region}:${AWS::AccountId}:rule/default/${Name}-20241017170127166100000001"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sqs:*"
            ],
            "Resource": "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${Environment}-${Name}-deadletter"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "arn:aws:s3:::${AWS::AccountId}-workloadconfig-${AWS::Region}-lambda-artifacts/unsigned/${Environment}-${Name}.zip"
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
                "lambda:*"
            ],
            "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:${Environment}-${Name}"
        },
    ]
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.78.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | git@github.com:apresdev/apres-terraform.git//modules/aws/lambda | rel/lambda/0.5.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_code_signing_arn_ssm_parameter"></a> [code\_signing\_arn\_ssm\_parameter](#input\_code\_signing\_arn\_ssm\_parameter) | ARN of the code signing config. This should typically be left blank to use the default. | `string` | `""` | no |
| <a name="input_code_signing_name_ssm_parameter"></a> [code\_signing\_name\_ssm\_parameter](#input\_code\_signing\_name\_ssm\_parameter) | Name of the code signing profile. This should typically be left blank to use the default. | `string` | `""` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function |
| <a name="output_rule_name"></a> [rule\_name](#output\_rule\_name) | Name of the CloudWatch Event Rule |
<!-- END_TF_DOCS -->