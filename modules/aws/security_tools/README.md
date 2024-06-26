# Apres AWS Security Tools

This module configures the security tools for your AWS organization. The module must ONLY be run on what AWS Organizations calls the "Audit" account!

This module sets up:
* AWS Security Hub
* Amazon GuardDuty, publishing to Security Hub
* Amazon EventBridge - subscribes to events from Security Hub, pushes to an SNS topic.
* AWS Chatbot
  * subscribes to the SNS topic
  * publishes to Slack and/or Teams

## Future enhancements
1. Add other services like Inspector, Detective, etc will be added in future versions.
2. Export GuardDuty events to S3. See [Export findings](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_exportfindings.html)


## Prerequisites

### Delegate Management

Run the [security_tools_delegator](../security_tools_delegator/README.md) module against the management account of your organization. This sets
up the delegation for the services that this module configures. This module will fail to deploy without that.

### Optional - Setup AWS Chatbot and Slack Integration
To skip this step, leave the `slack_workspace_id` as default (empty string).

In the Audit account, setup AWS Chatbot with Slack integration. This is a manual step and requires
both AWS permissions to create the Chatbot integration, and Slack permissions to install the AWS application.

Navigate in browser to the console of the Audit account, nagivate to AWS Chatbot in your primary region
(hint: https://us-east-2.console.aws.amazon.com/chatbot/home?region=us-east-2) and click the "Configure new client" button.

The full instructions are [here](https://docs.aws.amazon.com/chatbot/latest/adminguide/slack-setup.html), only do Step 1.

We recommend turning off the _AWS Chatbot AI powered improvements_ in the Account Settings -> Data privacy section in the AWS Console.

Once the Slack integration is setup, set the `slack_workspace_id` and `slack_security_hub_events_channel_id` variables
and apply this module to the Audit account and the rest of the integration will be configured.
* To find the Slack Workspace ID, see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID. Alternatively the AWS console will show the Workspace ID.
* To find the Slack Channel ID, right click on a channel and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N.

The Chatbot is granted ReadOnly access to SecurityHub, and the ability to update findings (UpdateFindings and BatchUpdateFindings) from users in the channel. To disable the ability to update findings, set the `allow_chatbot_update_findings`
to false.

### Optional - Setup AWS Chatbot and Microsoft Teams Integration
To skip this step, leave the `msteams_team_id` variable as default (empty string).

In the Audit account, setup AWS Chatbot with Microsoft Teams integration. This is a manual step and requires
both AWS permissions to create the Chatbot integration, and Microsoft Teams permissions to install the AWS application.

Navigate in browser to the console of the Audit account, nagivate to AWS Chatbot in your primary region
(hint: https://us-east-2.console.aws.amazon.com/chatbot/home?region=us-east-2) and click the "Configure new client" button.

The full instructions are [here](https://docs.aws.amazon.com/chatbot/latest/adminguide/teams-setup.html), only do Step 1.

We recommend turning off the _AWS Chatbot AI powered improvements_ in the Account Settings -> Data privacy section in the AWS Console.

Once the Microsoft Teams integration is setup, set the `msteams_team_id`, `msteams_channel_id` and `msteams_tenant_id` and apply this module to the Audit account.
* The AWS Console will conveniently show the Team ID and Tenant ID.
* The Channel Id is buried in the URL to the channel, and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990` and the Channel ID is between the slashes after `channel`, in this case the Channel ID is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.

The Chatbot is granted ReadOnly access to SecurityHub, and the ability to update findings (UpdateFindings and BatchUpdateFindings) from users in the channel. To disable the ability to update findings, set the `allow_chatbot_update_findings` to false.

# AWS IAM Permissions

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.45.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerting"></a> [alerting](#module\_alerting) | git@github.com:apresdev/apres-terraform.git//modules/aws/alerting | rel/alerting/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.security_hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.security_hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_guardduty_detector_feature.eks_runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_organization_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_securityhub_configuration_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy) | resource |
| [aws_securityhub_configuration_policy_association.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association) | resource |
| [aws_securityhub_finding_aggregator.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_organization_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_guardduty_detector.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/guardduty_detector) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | `"SecurityTools"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_guardduty_enable_eks_protection"></a> [guardduty\_enable\_eks\_protection](#input\_guardduty\_enable\_eks\_protection) | Enable GuardDuty to monitor EKS clusters | `bool` | `true` | no |
| <a name="input_guardduty_enable_lambda_protection"></a> [guardduty\_enable\_lambda\_protection](#input\_guardduty\_enable\_lambda\_protection) | Enable GuardDuty to monitor Lambda functions | `bool` | `true` | no |
| <a name="input_guardduty_enable_rds_protection"></a> [guardduty\_enable\_rds\_protection](#input\_guardduty\_enable\_rds\_protection) | Enable GuardDuty to monitor RDS instances | `bool` | `true` | no |
| <a name="input_guardduty_enable_s3_protection"></a> [guardduty\_enable\_s3\_protection](#input\_guardduty\_enable\_s3\_protection) | Enable GuardDuty to monitor S3 buckets | `bool` | `true` | no |
| <a name="input_msteams_channel_id"></a> [msteams\_channel\_id](#input\_msteams\_channel\_id) | The Microsoft Teams Channel ID for Security Hub Findings.<br>    The Channel Id is buried in the URL to the channel, and can be found in Teams using the "Get link to channel"<br>    menu option. A resulting URL might look like<br>    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`<br>    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i<br>    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`. | `string` | `""` | no |
| <a name="input_msteams_team_id"></a> [msteams\_team\_id](#input\_msteams\_team\_id) | The Microsoft Teams Team ID for Security Hub Findings. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_msteams_tenant_id"></a> [msteams\_tenant\_id](#input\_msteams\_tenant\_id) | The Microsoft Teams Tenant ID for Security Hub Findings. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_organization_root_id"></a> [organization\_root\_id](#input\_organization\_root\_id) | ID of the Root of the organization to associate the Security Hub configuration policy with. | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_security_hub_linking_mode"></a> [security\_hub\_linking\_mode](#input\_security\_hub\_linking\_mode) | One of ALL\_REGIONS\_EXPECT\_SPECIFIED, SPECIFIED\_REGIONS, or ALL\_REGIONS. If you have an SCP restricting regions, then<br>    you must use ALL\_REGIONS\_EXPECT\_SPECIFIED or SPECIFIED\_REGIONS. If you do not have an SCP restricting regions, then<br>    you can use ALL\_REGIONS, and leave security\_hub\_regions empty.<br><br>    The recommended approach is to have Control Tower govern only the regions you want to use. Control Tower will enable<br>    AWS Config in those regions, which is required by Security Hub. Then specify the supported regions in the security\_hub\_regions<br>    variable. | `string` | `"ALL_REGIONS"` | no |
| <a name="input_security_hub_regions"></a> [security\_hub\_regions](#input\_security\_hub\_regions) | A list of regions to link to the Security Hub master account. If you have an SCP restricting regions, then you must<br>    specify the regions here. If you do not have an SCP restricting regions, then you can leave this empty. | `list(string)` | `[]` | no |
| <a name="input_slack_security_hub_events_channel_id"></a> [slack\_security\_hub\_events\_channel\_id](#input\_slack\_security\_hub\_events\_channel\_id) | The Slack channel ID for Security Hub Events. To find a channel ID, in Slack, right click on a channel<br>  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N | `string` | `""` | no |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The Slack workspace ID for Security Hub Findings,<br>  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_hub_findings_sns_topic_arn"></a> [security\_hub\_findings\_sns\_topic\_arn](#output\_security\_hub\_findings\_sns\_topic\_arn) | n/a |
<!-- END_TF_DOCS -->