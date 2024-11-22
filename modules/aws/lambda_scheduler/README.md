# Lambda Scheduler

This module creates the artifacts required for a scheduled Lambda.

For details on the format of the `schedule_expression` variable, which uses cron or rate syntax,
see the [Using cron and rate](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html)
documentation.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`

```json
{
    "Effect": "Allow",
    "Action": [
        "events:PutRule",
        "events:DescribeRule",
        "events:PutTargets",
        "events:ListTargetsByRule",
        "events:RemoveTargets",
        "events:DeleteRule"
    ],
    "Resource": "arn:aws:events:${AWS::Region}:${AWS::AccountId}:rule/default/${environment}-${name}"
},
{
    "Effect": "Allow",
    "Action": [
        "lambda:GetFunction",
        "lambda:ListVersionsByFunction",
        "lambda:AddPermission",
        "lambda:RemovePermission",
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:${environment}-${name}"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.59.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.schedule_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_lambda_permission.allow_events_bridge_to_run_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_lambda_arn"></a> [lambda\_arn](#input\_lambda\_arn) | ARN of the Lambda function to be scheduled. If using the Apres Lambda module, this will be the output<br/>    variable `lambda_function_arn`. | `string` | n/a | yes |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Name of the Lambda function to be scheduled. If using the Apres Lambda module, this will be the output<br/>    variable `lambda_function_name`. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Schedule expression for the Lambda function. using cron or rate syntax. See<br/>    [Using cron and rate](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html)<br/>    documentation for details on the format. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_event_rule_arn"></a> [event\_rule\_arn](#output\_event\_rule\_arn) | The ARN for the generated CloudWatch Event Rule. |
| <a name="output_event_rule_name"></a> [event\_rule\_name](#output\_event\_rule\_name) | The Name for the generated CloudWatch Event Rule. |
<!-- END_TF_DOCS -->