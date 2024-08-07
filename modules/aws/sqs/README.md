# Apres DynamoDb Terraform module

## Overview

This module will create an SQS queue in accordance with best practices. SQS queue names do not need to be globally unique in AWS; however, to match
similar resources that must be unique (such as S3 buckets), the resulting name will have the following pattern:

`account-id`-`environment`-`region`-`name`

where:

* `account-id` is the 12 digit AWS account where the bucket is deployed.
* `environment` is the lower case `environment` variable passed into the terraform stack
* `region` is the AWS region where the bucket is deployed
* `name` is the lower case `name` variable passed into the terraform stack.

For example, if the stack is deployed with:

```hcl
module "sqs" {
  source      = "TBD" # value depends on your installation
  name        = "mytestqueue"
  environment = "SystemTest"
}
```

and the stack is deployed to the AWS account 12345689012 in us-east-2, the SQS queue name will be `123456789012-systemtest-us-east-2-mytestqueue`

### Enforced Best Practices

The following best practices are applied to the queue:

| Id         | Policy                                                |
|------------|-------------------------------------------------------|
| CKV_AWS_27 | Ensure all data stored in the SQS queue is encrypted. |

### Suppressed Best Practices

The following best practices ARE NOT implemented:

| Id          | Policy                                                                                               |
|-------------|------------------------------------------------------------------------------------------------------|
| CKV_AWS_72  | Ensure SQS policy does not allow ALL (*) actions.                                                    |
| CKV_AWS_168 | Ensure SQS queue policy is not public by only allowing specific services or principals to access it. |

## Example

```hcl
module "sqs" {
  source      = "../../../modules/sqs"
  environment = "Dev"
  name        = "mytestqueue"
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
  {
    "Effect": "Allow",
    "Action": [
      "sqs:CreateQueue",
      "sqs:UpdateQueue",
      "sqs:DeleteQueue",
      "sqs:TagQueue",
      "sqs:GetQueueAttributes",
      "sqs:ListQueueTags"
    ],
    "Resource": [
      "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${AWS::AccountId}-${environment}-${AWS::Region}-${name}",
      "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${AWS::AccountId}-${environment}-${AWS::Region}-${name}-deadletter"
    ]
  },
  {
    "Effect": "Allow",
    "Action": [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:DeleteAlarms"
    ],
    "Resource": [
      "arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:${AWS::AccountId}-${environment}-${AWS::Region}-${name}-error-rate-*",
      "arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:${AWS::AccountId}-${environment}-${AWS::Region}-${name}-projected-latency-*",
      "arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:${AWS::AccountId}-${environment}-${AWS::Region}-${name}-historical-latency-*"
    ]
  },
  {
    "Effect": "Allow",
    "Action": [
      "cloudwatch:DescribeAlarms"
    ],
    "Resource": "arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:*"
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

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                        | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudwatch_metric_alarm.error_rate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)               | resource    |
| [aws_cloudwatch_metric_alarm.historical_latency](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)       | resource    |
| [aws_cloudwatch_metric_alarm.projected_latency](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)        | resource    |
| [aws_sqs_queue.deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue)                                           | resource    |
| [aws_sqs_queue.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue)                                              | resource    |
| [aws_sqs_queue_redrive_allow_policy.deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                               | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                 | data source |

## Inputs

| Name                                                                                                                 | Description                                                                                                                                                                                                     | Type                                                                                                                                                                                                                  | Default                                                                                                                                                                | Required |
|----------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| <a name="input_application"></a> [application](#input\_application)                                                  | Application name, used for tagging AWS resources.                                                                                                                                                               | `string`                                                                                                                                                                                                              | n/a                                                                                                                                                                    |   yes    |
| <a name="input_component"></a> [component](#input\_component)                                                        | Component name, used for tagging AWS resources.                                                                                                                                                                 | `string`                                                                                                                                                                                                              | n/a                                                                                                                                                                    |   yes    |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags)                                             | Default set of tags to be applied to all resources                                                                                                                                                              | `map(string)`                                                                                                                                                                                                         | `{}`                                                                                                                                                                   |    no    |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds)                                          | (Optional) The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes). The default for this attribute is 0 seconds."                             | `number`                                                                                                                                                                                                              | `0`                                                                                                                                                                    |    no    |
| <a name="input_encryption_kms_key_id"></a> [encryption\_kms\_key\_id](#input\_encryption\_kms\_key\_id)              | The ARN of the KMS key to use for server-side encryption. If not provided,<br>  the default AWS managed key 'aws/sqs' will be used.                                                                             | `string`                                                                                                                                                                                                              | `null`                                                                                                                                                                 |    no    |
| <a name="input_environment"></a> [environment](#input\_environment)                                                  | Environment name, used for tagging AWS resources, and in the bucket name.                                                                                                                                       | `string`                                                                                                                                                                                                              | `"dev"`                                                                                                                                                                |    no    |
| <a name="input_error_rate_alarms"></a> [error\_rate\_alarms](#input\_error\_rate\_alarms)                            | n/a                                                                                                                                                                                                             | <pre>list(object({<br>    severity            = number<br>    datapoints_to_alarm = number<br>    evaluation_periods  = number<br>    period              = number<br>    threshold           = number<br>  }))</pre> | <pre>[<br>  {<br>    "datapoints_to_alarm": 15,<br>    "evaluation_periods": 15,<br>    "period": 60,<br>    "severity": 3,<br>    "threshold": 10<br>  }<br>]</pre>   |    no    |
| <a name="input_historical_latency_alarms"></a> [historical\_latency\_alarms](#input\_historical\_latency\_alarms)    | n/a                                                                                                                                                                                                             | <pre>list(object({<br>    severity            = number<br>    datapoints_to_alarm = number<br>    evaluation_periods  = number<br>    period              = number<br>    threshold           = number<br>  }))</pre> | <pre>[<br>  {<br>    "datapoints_to_alarm": 15,<br>    "evaluation_periods": 15,<br>    "period": 60,<br>    "severity": 2,<br>    "threshold": 1800<br>  }<br>]</pre> |    no    |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size)                               | (Optional) The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB). The default for this attribute is 262144 (256 KiB). | `number`                                                                                                                                                                                                              | `262144`                                                                                                                                                               |    no    |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds)    | (Optional) The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). The default for this attribute is 1209600 (14 days).                      | `number`                                                                                                                                                                                                              | `1209600`                                                                                                                                                              |    no    |
| <a name="input_name"></a> [name](#input\_name)                                                                       | Name of the queue, must be between 3 and 40 characters long and can contain only the following characters: a-z, A-Z, 0-9, \_, and -                                                                             | `string`                                                                                                                                                                                                              | n/a                                                                                                                                                                    |   yes    |
| <a name="input_owner"></a> [owner](#input\_owner)                                                                    | Owner of the resources, used for tagging AWS resources.                                                                                                                                                         | `string`                                                                                                                                                                                                              | n/a                                                                                                                                                                    |   yes    |
| <a name="input_policy"></a> [policy](#input\_policy)                                                                 | (Optional) The JSON policy for the SQS queue.                                                                                                                                                                   | `string`                                                                                                                                                                                                              | `""`                                                                                                                                                                   |    no    |
| <a name="input_projected_latency_alarms"></a> [projected\_latency\_alarms](#input\_projected\_latency\_alarms)       | n/a                                                                                                                                                                                                             | <pre>list(object({<br>    severity            = number<br>    datapoints_to_alarm = number<br>    evaluation_periods  = number<br>    period              = number<br>    threshold           = number<br>  }))</pre> | <pre>[<br>  {<br>    "datapoints_to_alarm": 10,<br>    "evaluation_periods": 10,<br>    "period": 60,<br>    "severity": 3,<br>    "threshold": 1800<br>  }<br>]</pre> |    no    |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | (Optional) The visibility timeout for the queue. An integer from 0 to 43200 (12 hours). The default for this attribute is 30. For more information about visibility timeout, see AWS docs.                      | `number`                                                                                                                                                                                                              | `30`                                                                                                                                                                   |    no    |

## Outputs

| Name                                                                                                                              | Description                   |
|-----------------------------------------------------------------------------------------------------------------------------------|-------------------------------|
| <a name="output_deadletter_queue_arn"></a> [deadletter\_queue\_arn](#output\_deadletter\_queue\_arn)                              | The ARN of the SQS queue.     |
| <a name="output_deadletter_queue_name"></a> [deadletter\_queue\_name](#output\_deadletter\_queue\_name)                           | The name of the SQS queue.    |
| <a name="output_error_rate_alarm_arns"></a> [error\_rate\_alarm\_arns](#output\_error\_rate\_alarm\_arns)                         | The ARN of error rate alarms. |
| <a name="output_historical_latency_alarm_arns"></a> [historical\_latency\_alarm\_arns](#output\_historical\_latency\_alarm\_arns) | The ARN of error rate alarms. |
| <a name="output_projected_latency_alarm_arns"></a> [projected\_latency\_alarm\_arns](#output\_projected\_latency\_alarm\_arns)    | The ARN of error rate alarms. |
| <a name="output_queue_arn"></a> [queue\_arn](#output\_queue\_arn)                                                                 | The ARN of the SQS queue.     |
| <a name="output_queue_name"></a> [queue\_name](#output\_queue\_name)                                                              | The name of the SQS queue.    |

<!-- END_TF_DOCS -->
