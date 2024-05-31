# Apres AWS Alerting

This module sets up alerting, via SNS, Email, Slack and/or Microsoft Teams. It is intended to be used by other modules
but can be uses standalone as well if needed.

This module sets up:
* an SNS topic with encryption and appropriate policies
* AWS Chatbot
  * subscribes to the SNS topic
  * publishes to Slack and/or Teams
* Optionally an email subscription to the SNS topic.

## Email Discussion

Some services, like Cost Anomaly and Budgets, have the option to send email directly, and you will likely want that
instead of an email subscription from the SNS topic, since formatting will likely be lost making the emails difficult to read.

If you do add email addresses, the receiver will need to confirm the subscription.

## Prerequisites - Configure Slack and/or Microsoft Teams

### Setup AWS Chatbot and Slack Integration
To skip this step, leave the `slack_workspace_id` as default (empty string).

You will need to setup AWS Chatbot with Slack integration. This is a manual step and requires
both AWS permissions to create the Chatbot integration, and Slack permissions to install the AWS application.

1. Navigate in a browser to the console of the Audit account, nagivate to AWS Chatbot in your primary region
(hint: https://us-east-2.console.aws.amazon.com/chatbot/home?region=us-east-2) and click the "Configure new client" button.
1. The full instructions are [here](https://docs.aws.amazon.com/chatbot/latest/adminguide/slack-setup.html), only do Step 1.
1. Apres recommends turning off the _AWS Chatbot AI powered improvements_ in the Account Settings -> Data privacy section in the AWS Console.
1. Invite the "AWS" Application to Slack channel. In the target Slack channel, type `@aws` and hit enter, you will be asked
if you want to add AWS to the channel, answer Yes.

Once the Slack integration is setup, set the `slack_workspace_id` and `slack_security_hub_events_channel_id` variables
and apply this module and the rest of the integration will be configured.
* To find the Slack Workspace ID, see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID. Alternatively the AWS console will show the Workspace ID.
* To find the Slack Channel ID, right click on a channel and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N.

### Setup AWS Chatbot and Microsoft Teams Integration
To skip this step, leave the `msteams_team_id` variable as default (empty string).

You will need to setup AWS Chatbot with Microsoft Teams integration. This is a manual step and requires
both AWS permissions to create the Chatbot integration, and Microsoft Teams permissions to install the AWS application.

1. Navigate in a browser to the console of the Audit account, nagivate to AWS Chatbot in your primary region
(hint: https://us-east-2.console.aws.amazon.com/chatbot/home?region=us-east-2) and click the "Configure new client" button.
1. The full instructions are [here](https://docs.aws.amazon.com/chatbot/latest/adminguide/teams-setup.html), only do Step 1.
1. Apres recommends turning off the _AWS Chatbot AI powered improvements_ in the Account Settings -> Data privacy section in the AWS Console.

Once the Microsoft Teams integration is setup, set the `msteams_team_id`, `msteams_channel_id` and `msteams_tenant_id` and apply this module to the Audit account.
* The AWS Console will conveniently show the Team ID and Tenant ID.
* The Channel Id is buried in the URL to the channel, and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990` and the Channel ID is between the slashes after `channel`, in this case the Channel ID is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed.

```json
{
  "Effect": "Allow",
  "Action": [
     "chatbot:*",
     "sns:*"
  ],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": "iam:*",
  "Resource": [
     "arn:aws:iam::${AWS::AccountId}:role/ChatBot*",
     "arn:aws:iam::${AWS::AccountId}:policy/ChatBot*",
     "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:security_hub_findings",
     "arn:aws:iam::${AWS::AccountId}:role/aws-service-role/management.chatbot.amazonaws.com/AWSServiceRoleForAWSChatbot"

  ]
},
{
  {
    "Action": [
      "kms:*"
    ],
    "Resource": [
      "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:*"
    ],
      "Effect": "Allow"
    }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.72.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.52.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.chatbot_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.msteams](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_sns_topic.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [awscc_chatbot_microsoft_teams_channel_configuration.default](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/chatbot_microsoft_teams_channel_configuration) | resource |
| [awscc_chatbot_slack_channel_configuration.default](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/chatbot_slack_channel_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.chatbot_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chatbot_policy_arns"></a> [chatbot\_policy\_arns](#input\_chatbot\_policy\_arns) | An AWS IAM Policy ARNs to attach to the Chatbot. The policies should contain the necessary<br>    permissions for the Chatbot to interact with the services. For example:<br>    ["arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"]<br><br>    This policy gives the users in your channels permission to access AWS resources, so take care to<br>    limit what is granted.<br><br>    If no policy ARN is given, a default empty policy is set, granting only sts:GetCallerIdentity permission. | `list(string)` | `[]` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to all resources | `map(string)` | <pre>{<br>  "application": "FinOps",<br>  "managed-by": "terraform",<br>  "owner": "Engineering"<br>}</pre> | no |
| <a name="input_email_addresses"></a> [email\_addresses](#input\_email\_addresses) | List of email addresses to send notifications to. At least one email address must be set. | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for tagging AWS resources. | `string` | `"Root"` | no |
| <a name="input_msteams_channel_id"></a> [msteams\_channel\_id](#input\_msteams\_channel\_id) | The Microsoft Teams Channel ID for nofications.  The Channel Id is buried in the URL to the channel,<br>    and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like<br>    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`<br>    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i<br>    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`. | `string` | `""` | no |
| <a name="input_msteams_team_id"></a> [msteams\_team\_id](#input\_msteams\_team\_id) | The Microsoft Teams Team ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_msteams_tenant_id"></a> [msteams\_tenant\_id](#input\_msteams\_tenant\_id) | The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prepended to the SNS topic | `string` | n/a | yes |
| <a name="input_publishing_services"></a> [publishing\_services](#input\_publishing\_services) | A list of AWS services which are granted access to publish to the SNS topic. The topic is created with encryption<br>    enabled, and the services need to be granted access to publish to the topic using the key. For example:<br>    ["events.amazonaws.com", "health.amazonaws.com", "config.amazonaws.com", "trustedadvisor.amazonaws.com"]<br><br>    "events.amazonaws.com" is for EventBridge (CloudWatch Events), and "costalerts.amazonaws.com" is for Budget<br>    and Cost Anomaly alerts. | `list(string)` | `[]` | no |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | The Slack channel ID for notifications. To find a channel ID, in Slack, right click on a channel<br>  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N | `string` | `""` | no |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The Slack workspace ID for notifications,<br>  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | The ARN of the SNS topic for alerting |
<!-- END_TF_DOCS -->