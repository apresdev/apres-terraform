# CloudWatch Alarms

This module is a wrapper around the
[cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm), providing a template to be used by the Apres monitoring stack.
The Alarms generated here do not have actions defined, but are used by the Monitoring account as a template
to create Grafana Alerts. See the [grafana_managed](../grafana_managed/README.md) module for
details on how this works.

For specifics on the alarm configuration, see the [Using Amazon CloudWatchAlarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html) page.

Anomaly detection is not supported in the initial version. The author ran across
[this bug](https://github.com/grafana/grafana/issues/69873#issuecomment-1711320519), and further investigation
is required.

## Examples

This example is to set an alarm on EC2 CPU usage for a single instance.

```hcl
module `cw_alarm_ec2` {
  source "..." # depends on where you get this module
  name   "MyEC2SimpleCPUAlarm"
  description "This is a simple alarm for triggering on CPU Usage."
  runbook "https://example.com/runbooks/cpu-usage"
  application "MyApp"
  component   "EC2"
  environment "Prod"
  severity "SEV1"
  namespace "EC2"
  metric "CPUUtilization"
  comparison_operator "GreaterThanThreshold"
  threshold 80
  statistic "Average"
  dimensions {
    InstanceId = "i-0090e48912d123456"
  }
}
```

The resulting alarm name will be "Prod-MyEC2SimpleCPUAlarm-SEV1". The description and runbook link will appear
in the CloudWatch console.

Three tags are added to alarms that are consumed by the Grafana Configurator:
* `severity` - the severity variable is used as value, such as SEV1.
* `runbook` - the runbook URL is set as the value
* `source` - the value `cloudwatch_alarm_module` is set. This isn't strictly necessary but
  just in case a client creates an alarm with severity and runbook, this tag acts as the differentiator.


## Treatment of Missing Data

CloudWatch and Grafana handle missing data differently. There are legitimate cases where there are no values, for example
a 5xx error on a load balancer that last occurred 24 hours ago, with no further data. In CloudWatch we would treat the "missing" data as "notBreaching", but in Grafana, the alert would remain triggered (alerting) until a new value appears.

Because of that, in Grafana a missing value needs to be set to something. The following algorithm is used (using shorthand values for comparison_operator)
* if `var.treat_missing_data` is `breaching`
   * if `var.comparison_operator` is > or >= then in Grafana the value will be set to `var.threshold` + 1
   * if `var.comparator` is < or <= then in Grafana the value will be set to zero
* else if `var.treat_missing_data` is `notBreaching`
   * if `var.comparator` is > or >= then in Grafana the value will be set to 0
   * if `var.comparator` is < or <= then in Grafana the value will be set to `var.threshold` + 1

## AWS Permissions

The following AWS Permissions are required to use this module.

```json
{
  "Effect": "Allow",
  "Action": [
    "cloudwatch:*Alarm"
  ],
  "Resource": "*"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.74.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.standard_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_comparison_operator"></a> [comparison\_operator](#input\_comparison\_operator) | Comparison operator to use for the alarm. The following are supported:<br/>    GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, or LessThanOrEqualToThreshold. | `string` | `"GreaterThanOrEqualToThreshold"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description of the alarm, will be displayed in the CloudWatch dashboard as well as the alerts in<br/>    Slack/Teams/Email.<br/><br/>    CloudWatch supports a subset of Markdown, see the AWS Console for details. The runbook<br/>    link will be appended to the end of the description. | `string` | n/a | yes |
| <a name="input_dimensions"></a> [dimensions](#input\_dimensions) | Dimensions to filter the metric by. See<br/>    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html for more details. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | Number of periods to evaluate the metric for. | `number` | `1` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | Name of the metric. See<br/>    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html for more details. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for the metric. See<br/>    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html for more details. | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_period"></a> [period](#input\_period) | Period in seconds over which the specified statistic is applied. | `number` | `300` | no |
| <a name="input_runbook"></a> [runbook](#input\_runbook) | URL for the runbook outlining actions to take when the alarm triggers. This is required,<br/>    and it will be included in the alert message sent to Slack/Teams/Email. | `string` | n/a | yes |
| <a name="input_severity"></a> [severity](#input\_severity) | Set the severity of the alarm. The severity will be appended to the alarm name, and the alarm<br/>    will be tagged with the severity. Values are, with typical response times described:<br/>    * SEV1 - System is down or critical business impact, requires immediate attention.<br/>    * SEV2 - System is degraded or has a moderate business impact, requires same-day attention.<br/>    * SEV3 - System is experiencing minor issues or has a low business impact, requires attention within 3 days. | `string` | n/a | yes |
| <a name="input_statistic"></a> [statistic](#input\_statistic) | Statistic to use for the alarm. | `string` | `"Sum"` | no |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | Threshold for the alarm. Ignored if using anomaly detection. | `number` | `1` | no |
| <a name="input_treat_missing_data"></a> [treat\_missing\_data](#input\_treat\_missing\_data) | Sets how this alarm is to handle missing data points. The following values are supported:<br/>    missing, ignore, breaching and notBreaching. Defaults to notBreaching. | `string` | `"notBreaching"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arn"></a> [alarm\_arn](#output\_alarm\_arn) | The ARN of the CloudWatch Alarm |
| <a name="output_alarm_name"></a> [alarm\_name](#output\_alarm\_name) | The name of the CloudWatch Alarm. |
<!-- END_TF_DOCS -->