# Apres AWS Alerting

This module sets up alerting via SNS, Email, Slack and/or Microsoft Teams. It is intended to be used by other modules
but can be used standalone as well if needed.

This module sets up:
* SNS topic(s) with encryption and appropriate policies
* AWS Chatbot
  * subscribes to the SNS topic(s)
  * publishes to Slack and/or Teams
* IAM Roles/Polies for Chatbot.

## Future Considerations

In this initial version only integrations with Slack and Teams are supported. For future integrations
with tools such as PagerDuty, OpsGenie, FireHydrant, etc, this module acts as an abstraction for those
services, as the integrations are typically implemented using SNS.

## Known Issues

Due to a bug in the AWS terraform provider, only ONE Teams channel is supported per AWS account.
Creating the second one will fail leaving the configuration in a state that will need manual
recovery. See [the bug](https://github.com/hashicorp/terraform-provider-aws/issues/38943) for details.

## Multiple Regions

Chatbot is a _unique_ global service. The Slack Workspace and/or Teams integration needs to be manually configured
once per AWS account, see [Prerequisites](#prerequisites---configure-slack-andor-microsoft-teams). Once
configured, channel configurations can be deployed regionally.

The catch is that Slack and Team channels are region-specific. That is, you cannot configure the same
Chatbot configuration in two regions to write to a single channel, and you will need a channel per region.

## Channel Configuration

MS Teams and Slack integrations are both supported, but configured separately. The channel configuration in
the `chatbot_slack_config` and `chatbot_msteams_config` shares some common attributes outlined here.

Using the following example:
```hcl
module "alerting" {
  # ...
  chatbot_slack_config = [
    {
      name = "cloudwatchalarms"
      publishing_services = ["cloudwatch.amazonaws.com"]
      slack_channel_id = "C07XY6M5ABC"
    }
  ]
}
```
the elements of the `chatbot_slack_config` are:
* `name`: This is the name of the configuration, and will be used to create the SNS topic with the name of
  `apres-alerting-${name}`, in this example `apres-alerting-cloudwatchalarms`.
* `publishing_services`: A list of AWS services which are granted access to publish to the SNS topic. The topic
  is created with encryption enabled, and the services need to be granted access to publish to the topic using
  the KMS key. `events.amazonaws.com` is for EventBridge, `cloudwatch.amazonaws.com` is for CloudWatch Alarms,
  `costalerts.amazonaws.com` is for Budget and Cost Anomaly alerts.
* `slack_channel_id` is the Slack channel ID for notifications. To find a channel ID, in Slack,
  right click on a channel and select "View channel details" and the Channel ID should be at the
  bottom, like `C07S3JC2C0N`.

If configuring MS Teams, use the `chatbot_msteams_config` object. The same values apply as above, with
the difference being the `msteams_channel_id` instead of the `slack_channel_id`. The Channel
ID is buried in the URL to the channel, and can be found in Teams using the "Get link to channel"
menu option. A resulting URL might look like
`https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`
and the Channel ID is between the slashes after `channel`, in this case the Channel ID
is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.

## Prerequisites - Configure Slack and/or Microsoft Teams

These steps are required once per AWS account. Deployment will fail if this is not completed first.

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

Once the Slack integration is setup, set the `slack_workspace_id` and apply this module and
the rest of the integration will be configured.
* To find the Slack Workspace ID, see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID. Alternatively the AWS console will show the Workspace ID.
* To find the Slack Channel ID, right click on a channel and select "View channel details" and the Channel ID should be at the bottom, like `C07S3JC2C0N`.

### Setup AWS Chatbot and Microsoft Teams Integration
To skip this step, leave the `msteams_team_id` variable as default (empty string).

You will need to setup AWS Chatbot with Microsoft Teams integration. This is a manual step and requires
both AWS permissions to create the Chatbot integration, and Microsoft Teams permissions to install the AWS application.

1. Navigate in a browser to the console of the Audit account, nagivate to AWS Chatbot in your primary region
(hint: https://us-east-2.console.aws.amazon.com/chatbot/home?region=us-east-2) and click the "Configure new client" button.
1. The full instructions are [here](https://docs.aws.amazon.com/chatbot/latest/adminguide/teams-setup.html), only do Step 1.
1. Apres recommends turning off the _AWS Chatbot AI powered improvements_ in the Account Settings -> Data privacy section in the AWS Console.

Once the Microsoft Teams integration is setup set the `msteams_team_id`,
and `msteams_tenant_id` respectively, and create the `chatbot_msteams_config` section.
* The AWS Console will conveniently show the Team ID and Tenant ID.
* The Channel Id is buried in the URL to the channel, and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990` and the Channel ID is between the slashes after `channel`, in this case the Channel ID is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.

## Testing

Automated testing is not available for this module, because of the manual configuration steps required.

See the [README](tests/fixtures/README.md) for instructions on how to manually test this module.

## AWS IAM Permissions

The following permissions are required to use this module, substitute `${AWS::AccountId}` with the AWS account
ID where this is deployed, and `${AWS::Region}` with the region where this is deployed. Unfortunately the
KMS resource stanza cannot be further limited due to how the KMS key IDs are generated.

```json
{
    "Effect": "Allow",
    "Action": [
        "iam:*"
    ],
    "Resource": [
      "arn:aws:iam::${AWS::AccountId}:policy/*ChatBot*",
      "arn:aws:iam::${AWS::AccountId}:role/*ChatBot"
    ]
},
{
    "Effect": "Allow",
    "Action": [
        "kms:*"
    ],
    "Resource": "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/*"
},
{
    "Effect": "Allow",
    "Action": [
        "sns:*"
    ],
    "Resource": "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:apres-alerting-*"
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.74.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.46.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git::https://github.com/apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/2.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_chatbot_slack_channel_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/chatbot_slack_channel_configuration) | resource |
| [aws_chatbot_teams_channel_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/chatbot_teams_channel_configuration) | resource |
| [aws_iam_policy.chatbot_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.msteams](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.msteams](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_sns_topic.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.chatbot_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_chatbot_msteams_config"></a> [chatbot\_msteams\_config](#input\_chatbot\_msteams\_config) | A list of configuration objects for Slack channels. See the "Channel Configuration" section<br>    in the README for more details.<br><br>    The SNS topic names will be prefixed with "apres-alerting-" and postfixed with the name. | <pre>list(object({<br>    name                = string<br>    publishing_services = list(string)<br>    msteams_channel_id  = string<br>  }))</pre> | `[]` | no |
| <a name="input_chatbot_slack_config"></a> [chatbot\_slack\_config](#input\_chatbot\_slack\_config) | A list of configuration objects for Slack channels. See the "Channel Configuration" section<br>    in the README for more details.<br><br>    The SNS topic names will be prefixed with "apres-alerting-" and postfixed with the name. | <pre>list(object({<br>    name                = string<br>    publishing_services = list(string)<br>    slack_channel_id    = string<br>  }))</pre> | `[]` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | `"Alerting"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_msteams_team_id"></a> [msteams\_team\_id](#input\_msteams\_team\_id) | The Microsoft Teams "Team ID" for notifications. This is displayed in the AWS Console. If not set,<br>    Teams integration will not be enabled. | `string` | `""` | no |
| <a name="input_msteams_tenant_id"></a> [msteams\_tenant\_id](#input\_msteams\_tenant\_id) | The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Name appended to the SNS topic, and used to identify other resources. | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The Slack workspace ID for notifications,<br>  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it.<br><br>  If not set, Slack integration will not be enabled. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arns"></a> [sns\_topic\_arns](#output\_sns\_topic\_arns) | List of ARNs for the SNS topics created for alerting. |
<!-- END_TF_DOCS -->