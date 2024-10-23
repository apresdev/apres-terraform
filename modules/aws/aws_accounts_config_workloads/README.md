# Account configuration for Workload Accounts

This module is meant to be applied to every AWS account where you deploy workloads, per region. It sets up
the following:
* CloudWatch Logs with KMS encryption
* If enabled, allows API Gateway to log to CloudWatch Logs.
* Creates an S3 bucket for Load Balancer access logs, by default keeping access logs for 365 days. The bucket
  name will be `<account-id>-workloadconfig-<region>-load-balancer-logs`.
* Adds the ECS event lifecyle to monitor for ECS tasks that are in a crash loop.

It also sets up ChatBot in the region specified by the `chatbot_primary_region` variable,
for CloudWatch Alarms integration. ChatBot is a global service, so ChatBot is only deployed
in a single region, and the SNS alerting topic it subscribes to can be used from all regions.
See the next section for more details.

## CloudWatch Alarms

CloudWatch Alarms created with the Apres `cloudwatch_alarms` module will automatically send messages
to ChatBot, and ChatBot in turn will notify in Slack/Teams/Email depending on the configuration passed into
this module.

Future revisions may change the alerting mechanism, Apres recommends using the `cloudwatch_alarms` module
to stay up to date with changes.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Replace `${AWS::AccountID}` with the AWS Account ID where this is deployed, and `${AWS::Region}`
with the region where this is deployed.

In addition to the permissions below, the permissions of the [ecs_events](../ecs_events/README.md)
and [alertings](../alerting/README.md) will also need to be applied!

```json
{
  "Effect": "Allow",
  "Action": [
    "apigateway:UpdateAccount",
    "cloudwatch:*",
    "kms:*",
    "logs:*"
  ],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": [
    "iam:*"
  ],
  "Resource": "arn:aws:iam::${AWS::AccountID}:role/ApresAPIGatewayCloudWatchLogsRole*"
},
{
  "Sid": "AllowManageAPIGWAccountSettings",
  "Effect": "Allow",
  "Action": [
    "apigateway:*"
  ],
  "Resource": "arn:aws:apigateway:${AWS::Region}::/account"
},
{
  "Sid": "AllowManageS3LoadBalancerBucket",
  "Effect": "Allow",
  "Action": [
    "s3:*"
  ],
  "Resource": "arn:aws:s3:::*-load-balancer-logs"
},
{
  "Sid": "DenyS3Delete",
  "Effect": "Deny",
  "Action": [
    "s3:Delete*"
  ],
  "Resource": "arn:aws:s3:::*-load-balancer-logs"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.72.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerting"></a> [alerting](#module\_alerting) | git@github.com:apresdev/apres-terraform.git//modules/aws/alerting | rel/alerting/1.0.1 |
| <a name="module_cloudwatchlogs_regional"></a> [cloudwatchlogs\_regional](#module\_cloudwatchlogs\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs_regional | rel/cloudwatchlogs_regional/1.2.0 |
| <a name="module_ecs_events"></a> [ecs\_events](#module\_ecs\_events) | git@github.com:apresdev/apres-terraform.git//modules/aws/ecs_events | rel/ecs_events/0.1.0 |
| <a name="module_lambda_regional"></a> [lambda\_regional](#module\_lambda\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/lambda_regional | rel/lambda_regional/0.2.4 |
| <a name="module_load_balancer_logs_bucket"></a> [load\_balancer\_logs\_bucket](#module\_load\_balancer\_logs\_bucket) | git@github.com:apresdev/apres-terraform.git//modules/aws/s3 | rel/s3/3.0.1 |
| <a name="module_messaging_regional"></a> [messaging\_regional](#module\_messaging\_regional) | git@github.com:apresdev/apres-terraform.git//modules/aws/messaging_regional | rel/messaging_regional/0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.nlb_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.post2022_lb_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.pre2022_lb_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chatbot_primary_region"></a> [chatbot\_primary\_region](#input\_chatbot\_primary\_region) | ChatBot will send CloudWatch Alarms to Slack or Teams (if configured) but ChatBot is a global service. Set this<br/>    to the region name, like "us-east-2" or "us-west-2" where the primary ChatBot is configured.<br/><br/>    ChatBot must be configured in each account before being deployed, with Slack and/or Teams integration. See the<br/>    instructions in the Apres `alerting` terraform module for more information.<br/><br/>    Leaving this blank will disable ChatBot, and the Slack and Teams variables will be ignored. | `string` | `""` | no |
| <a name="input_email_addresses"></a> [email\_addresses](#input\_email\_addresses) | List of email addresses to send notifications to. | `list(string)` | `[]` | no |
| <a name="input_enable_api_gateway_logging"></a> [enable\_api\_gateway\_logging](#input\_enable\_api\_gateway\_logging) | Enable API Gateway logging to CloudWatch Logs. This requires an IAM Role and an API Gateway<br/>    configuration per region. By default this is disabled, enable if you are planning to<br/>    use API Gateway in the account this is deployed in. | `bool` | `false` | no |
| <a name="input_msteams_channel_id"></a> [msteams\_channel\_id](#input\_msteams\_channel\_id) | The Microsoft Teams Channel ID for nofications.  The Channel Id is buried in the URL to the channel,<br/>    and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like<br/>    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`<br/>    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i<br/>    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`. | `string` | `""` | no |
| <a name="input_msteams_team_id"></a> [msteams\_team\_id](#input\_msteams\_team\_id) | The Microsoft Teams "Team ID" for notifications. This is displayed in the AWS Console. If not set,<br/>    Teams integration will not be enabled. | `string` | `""` | no |
| <a name="input_msteams_tenant_id"></a> [msteams\_tenant\_id](#input\_msteams\_tenant\_id) | The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console. | `string` | `""` | no |
| <a name="input_retain_load_balancer_logs_days"></a> [retain\_load\_balancer\_logs\_days](#input\_retain\_load\_balancer\_logs\_days) | Number of days to retain the load balancer logs in the S3 bucket. By default, this is set to 365.<br/>    Setting this to -1 will retain logs indefinitely. | `number` | `365` | no |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | The Slack channel ID for notifications. To find a channel ID, in Slack, right click on a channel<br/>  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N | `string` | `""` | no |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The Slack workspace ID for notifications,<br/>  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it.<br/><br/>  If not set, Slack integration will not be enabled. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alerts_sns_topic_arn"></a> [alerts\_sns\_topic\_arn](#output\_alerts\_sns\_topic\_arn) | The ARN of the SNS Topic for alerts, or empty string if it does not exist in this region. |
<!-- END_TF_DOCS -->