# Cost Management

## Introduction

Setting up alerts for cost anomalies and budgets is vital for three different reasons:
1. Avoid nasty surprises at month end when the AWS bill is higher than expected.
1. Unexpectedly high costs can be an indication of an operational issue and should be investigated.
1. Unexpectedly high costs can be an indication of a security event and shoudl be investigated.

This module sets up simple but powerful alerts and thresholds, using both Budgets and Cost Anomaly Detection.

Cost Allocation Tags are critical to reporting, but need to be setup ahead of time, this module takes care of that.

## Setup

This should ONLY be applied to the AWS account where consolidated billing occurs, typically your root account.

The Cost Anomaly Detection rules are fairly simple but powerful - if an anomaly is greater than `alert_on_percentage`
AND greater than `alert_on_dollars` then alert. In practice this combination is sufficient to remove false positives,
such as a 1200% increase in a service where the dollar spend is $0.10. As your AWS environment becomes more complex this will likely no longer suffice.

The Cost Allocation Tags defaults include the tags which the Apres terraform modules provide. You may wish to add more.

## Alerting

You have three options for alerting, and can use any or all as needed.
* Email - include the email address(es) to alert to in the `email_addresses` field. Emails will be sent directly from the Cost Anomaly Detection or Budget services to maintain formatting.
* Slack - via AWS ChatBot. Set appropriate values for `slack_workspace_id` and `slack_channel_id`, see below for configuration.
* Microsoft Teams - via AWS ChatBot. Set appropriate values for `msteams_team_id`, `msteams_channel_id` and `msteams_tenant_id`, see below for configuration.

### Configuring Teams and Slack

Configuration for Microsoft Teams and Slack unfortunately requires a manual step, see the [alerting module](../alerting/README.md) for details.

## AWS IAM Permissions

The following permissions are required to use this module. This includes
permissions required any submodules. Substitute `${AWS::AccountId}` with the Account ID where this is deployed, and `${AWS::Region}` with the correct region.

```json
{
    "Effect": "Allow",
    "Action": [
        "budgets:*",
        "ce:*",
        "kms:*",
    ],
    "Resource": "*"
},
{
    "Effect": "Allow",
    "Action": [
        "iam:*"
    ],
    "Resource": [
        "arn:aws:iam::${AWS::AccountId}:policy/ChatBot*",
        "arn:aws:iam::${AWS::AccountId}:role/ChatBot*"
    ]
},
{
    "Effect": "Allow",
    "Action": [
        "sns:*"
    ],
    "Resource": "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:apres-alerting-costmanagement"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.52.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerting"></a> [alerting](#module\_alerting) | ../alerting | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_ce_anomaly_monitor.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ce_anomaly_monitor) | resource |
| [aws_ce_anomaly_subscription.chat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ce_anomaly_subscription) | resource |
| [aws_ce_anomaly_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ce_anomaly_subscription) | resource |
| [aws_ce_cost_allocation_tag.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ce_cost_allocation_tag) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_anomaly_alert_on_dollars"></a> [anomaly\_alert\_on\_dollars](#input\_anomaly\_alert\_on\_dollars) | Alert if a Cost Anomaly is greater than or equal to this dollar amount. This condition will be combined with<br>    the anomaly\_alert\_on\_percentage condition using an AND operator. | `number` | `100` | no |
| <a name="input_anomaly_alert_on_percentage"></a> [anomaly\_alert\_on\_percentage](#input\_anomaly\_alert\_on\_percentage) | Alert if a Cost Anomaly is greater than or equal to this percentage. This condition will be combined with<br>    the anomaly\_alert\_on\_dollars condition using an AND operator. Valid values can be more than 100%. | `number` | `10` | no |
| <a name="input_budget_alert_thresholds"></a> [budget\_alert\_thresholds](#input\_budget\_alert\_thresholds) | The thresholds for budget alerts. Each item is a different alert. The "percent" is the percentage of the `budget_limit`<br>    variable, the value can be more than 100%. For example, you could set a threshold of 200% to alert when the spend is<br>    200% of the budget.<br><br>    The "type" is one of FORECASTED or ACTUAL.<br><br>    The default values are to alert when:<br>    * AWS Budgets forecasts 85% `budget_limit` will be reached<br>    * AWS Budgets forecasts 100% of the `budget_limit` will be reached<br>    * AWS Budgets calculates 85% of the `budget_limit` has been reached<br>    * AWS Budgets calculates 100% of the `budget_limit` has been reached | <pre>list(object({<br>    percent = number<br>    type    = string<br>  }))</pre> | <pre>[<br>  {<br>    "percent": 85,<br>    "type": "FORECASTED"<br>  },<br>  {<br>    "percent": 100,<br>    "type": "FORECASTED"<br>  },<br>  {<br>    "percent": 85,<br>    "type": "ACTUAL"<br>  },<br>  {<br>    "percent": 100,<br>    "type": "ACTUAL"<br>  }<br>]</pre> | no |
| <a name="input_budget_limit"></a> [budget\_limit](#input\_budget\_limit) | The limit set for the default Budget, in USD, for monthly spend.  Alerts will be generated<br>    when the predicted or actual monthly spend exceeds this limit.<br><br>    The $ amount is the spend for all accounts in the organization. At this time budgets per account or tag groups are<br>    not supported yet. | `number` | `100` | no |
| <a name="input_budget_name"></a> [budget\_name](#input\_budget\_name) | The name of the default Budget. This name will be used to create the Budget in AWS and will be used in the<br>    alerts generated by the Budget. | `string` | `"Default Budget"` | no |
| <a name="input_cost_allocation_tags"></a> [cost\_allocation\_tags](#input\_cost\_allocation\_tags) | Set of Cost Allocation tags to be used for cost allocation. These tags become available in Cost Explorer and make<br>    reporting much easier.<br>    The default set of cost allocation tags here is what is used by Apres modules:<br>    * environment: Name of the environment, used to differentiate instances, like Dev, Test, Prod, etc.<br>    * application: Overall application name.<br>    * component: Component of an application<br>    * owner: Owner of the resource, typically Engineering but could be something else.<br>    * managed-by: Name of the tool managing the resources, usually Terraform but could be something else. | `list(string)` | <pre>[<br>  "environment",<br>  "application",<br>  "component",<br>  "owner",<br>  "managed-by"<br>]</pre> | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to all resources | `map(string)` | <pre>{<br>  "application": "FinOps",<br>  "managed-by": "terraform",<br>  "owner": "Engineering"<br>}</pre> | no |
| <a name="input_email_addresses"></a> [email\_addresses](#input\_email\_addresses) | List of email addresses to send notifications to. At least one email address must be set. | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for tagging AWS resources. | `string` | `"Root"` | no |
| <a name="input_frequency"></a> [frequency](#input\_frequency) | Frequency of the alerts, one of DAILY, IMMEDIATE, or WEEKLY. Note that IMMEDIATE alerts are not supported for email<br>  subscriptions. If email addresses are supplied and frequency is set to IMMEDIATE, the email subscriptions will be<br>  set to DAILY. If email addresses are supplied and frequency is set to WEEKLY, the email subscriptions will be set to WEEKLY. | `string` | `"DAILY"` | no |
| <a name="input_msteams_channel_id"></a> [msteams\_channel\_id](#input\_msteams\_channel\_id) | The Microsoft Teams Channel ID for notifications.  The Channel Id is buried in the URL to the channel,<br>    and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like<br>    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`<br>    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i<br>    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.<br><br>    If left blank, MS Teams integration will not be enabled. | `string` | `""` | no |
| <a name="input_msteams_team_id"></a> [msteams\_team\_id](#input\_msteams\_team\_id) | The Microsoft Teams Team ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_msteams_tenant_id"></a> [msteams\_tenant\_id](#input\_msteams\_tenant\_id) | The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | The Slack channel ID for notifications. To find a channel ID, in Slack, right click on a channel<br>  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N. If left blank<br>  Slack integration will not be enabled. | `string` | `""` | no |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The Slack workspace ID for notifications,<br>  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it. | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->