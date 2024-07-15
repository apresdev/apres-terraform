# AWS Account Config Root

This module configures the AWS Root account. It includes:
* Manage the primary contacts as well as contacts for billing, security and operations across the AWS Organization
* Delegate security tools configuration - SecurityHub and GuardDuty - to the audit account.
* Setup Cost Management tools - Budgets and Cost Anomaly Detection - with alerting via email, Slack and/or Teams
* The Apres AWS account module containing global account configuration `aws_accounts_config_global`

It is critical to set the correct contact information, as AWS will use the contacts in case of a security or
billing question, and not responding may result in suspension or termination of the AWS services.


## Cost Management

The module supports three options for alerting on Cost Anomalies and Budgets, you may use any or all as needed:
* Email - include the email address(es) to alert to in the `email_addresses` field. Emails will be sent directly from the Cost Anomaly Detection or Budget services to maintain formatting.
* Slack - via AWS ChatBot. Set appropriate values for `slack_workspace_id` and `slack_channel_id`, see below for configuration.
* Microsoft Teams - via AWS ChatBot. Set appropriate values for `msteams_team_id`, `msteams_channel_id` and `msteams_tenant_id`, see below for configuration.

### Configuring Teams and Slack

Configuration for Microsoft Teams and Slack unfortunately requires a manual step, see the [alerting module](../alerting/README.md) for details.

## AWS IAM Permissions

The following permissions are required to use this module, substitute `${AWS::AccountId}` with the Account ID of the root account. This snippet is in CloudFormation yaml format:

```yaml
- Sid: AllowManageContactInfo
  Effect: Allow
  Action: account:*
  Resource: "*"
- Sid: AllowManageCostAlerts
  Effect: Allow
  Action:
    - budgets:*
    - ce:*
    - chatbot:*
    - cloudformation:*
    - kms:*
  Resource: "*"
- Sid: AllowManageCostAlertsIAM
  Effect: Allow
  Action:
    - iam:*
  Resource:
    - !Sub "arn:aws:iam::${AWS::AccountId}:policy/ChatBot*"
    - !Sub "arn:aws:iam::${AWS::AccountId}:role/ChatBot*"
- Sid: AllowManageCostAlertsSNS
  Effect: Allow
  Action:
    - sns:*
  Resource:
    - !Sub "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:apres-alerting-costmanagement"
- Sid: AllowDelegateSecurityConfig
  Effect: Allow
  Action:
    - guardduty:*OrganizationAdminAccount
    - guardduty:List*
    - guardduty:Get*
    - securityhub:*OrganizationAdminAccount
    - securityhub:List*
    - securityhub:Get*
    - ec2:DescribeRegions
    - organizations:DescribeOrganization
  Resource: "*"
- Sid: AllowManageIAMPasswordPolicy
  Effect: Allow
  Action:
    - iam:DeleteAccountPasswordPolicy
    - iam:GetAccountPasswordPolicy
    - iam:UpdateAccountPasswordPolicy
  Resource: "*"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.58.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_accounts_config_global"></a> [aws\_accounts\_config\_global](#module\_aws\_accounts\_config\_global) | git@github.com:apresdev/apres-terraform.git//modules/aws/aws_accounts_config_global | rel/aws_accounts_config_global/0.1.0 |
| <a name="module_costmanagement"></a> [costmanagement](#module\_costmanagement) | git@github.com:apresdev/apres-terraform.git//modules/aws/cost_management | rel/cost_management/1.0.2 |
| <a name="module_security_tools_delegator"></a> [security\_tools\_delegator](#module\_security\_tools\_delegator) | git@github.com:apresdev/apres-terraform.git//modules/aws/security_tools_delegator | rel/security_tools_delegator/0.2.1 |

## Resources

| Name | Type |
|------|------|
| [aws_account_alternate_contact.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_alternate_contact.operations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_alternate_contact.security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_primary_contact.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_primary_contact) | resource |
| [aws_account_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_region) | resource |
| [aws_organizations_organization.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alternate_contact_info"></a> [alternate\_contact\_info](#input\_alternate\_contact\_info) | Alternate contact information. The information provided will be set on all the AWS accounts in<br>    the AWS Organization.<br><br>    There are three types of alternate contacts in AWS: Operations, Security, and Billing.<br>    For simplicity they can all be set to the same values in this provider by setting `type`<br>    to the string `default`. Else a separate element should be set for each type of<br>    `operations`, `security`, and `billing`.<br><br>    Apres recommends the email address(es) to be a distribution list, not an individual's email address.<br>    These contacts are used by AWS to notify of security events and billing issues, and the<br>    email addresses given should be monitored. Failing to respond to security or billing events may result<br>    in termination of services.<br><br>    For example, setting all contacts to the same info:<pre>hcl<br>      module "organizations" {<br>        # ...<br>        alternate_contact_info = {<br>          "default" = {<br>            name          = "Micky McGuire"<br>            title         = "CEO"<br>            email_address = "micky.mcguire@acme.com"<br>            phone_number  = "+1 234-567-8901"<br>          }<br>        }<br>      }</pre>Or setting different contacts for each type:<pre>hcl<br>      module "organizations" {<br>        # ...<br>        alternate_contact_info = {<br>          "operations" = [<br>            {<br>              name          = "Micky McGuire"<br>              # omitted for brevity ...<br>            }<br>          ],<br>          "security" = [<br>            {<br>              name          = "Micky McGuire"<br>              # omitted for brevity ...<br>            }<br>          ],<br>          # ...<br>        }<br>      }</pre> | <pre>map(object({<br>    name          = string<br>    title         = string<br>    email_address = string<br>    phone_number  = string<br>  }))</pre> | n/a | yes |
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | The AWS account ID of the Audit account, which will be used to delegate configuration of the Security Tools. If not<br>    given the module will attempt to lookup the account by the case-insensitive name "audit" in the organization. | `string` | `""` | no |
| <a name="input_budget_alert_thresholds"></a> [budget\_alert\_thresholds](#input\_budget\_alert\_thresholds) | The thresholds for budget alerts. Each item is a different alert. The "percent" is the percentage of the `budget_limit`<br>    variable, the value can be more than 100%. For example, you could set a threshold of 200% to alert when the spend is<br>    200% of the budget.<br><br>    The "type" is one of FORECASTED or ACTUAL.<br><br>    The default values are to alert when:<br>    * AWS Budgets forecasts 85% `budget_limit` will be reached<br>    * AWS Budgets forecasts 100% of the `budget_limit` will be reached<br>    * AWS Budgets calculates 85% of the `budget_limit` has been reached<br>    * AWS Budgets calculates 100% of the `budget_limit` has been reached | <pre>list(object({<br>    percent = number<br>    type    = string<br>  }))</pre> | <pre>[<br>  {<br>    "percent": 85,<br>    "type": "FORECASTED"<br>  },<br>  {<br>    "percent": 100,<br>    "type": "FORECASTED"<br>  },<br>  {<br>    "percent": 85,<br>    "type": "ACTUAL"<br>  },<br>  {<br>    "percent": 100,<br>    "type": "ACTUAL"<br>  }<br>]</pre> | no |
| <a name="input_budget_limit"></a> [budget\_limit](#input\_budget\_limit) | The limit set for the default Budget, in USD, for monthly spend.  Alerts will be generated<br>    when the predicted or actual monthly spend exceeds this limit.<br><br>    The $ amount is the spend for all accounts in the organization. At this time budgets per account or tag groups are<br>    not supported yet. | `number` | `100` | no |
| <a name="input_budget_name"></a> [budget\_name](#input\_budget\_name) | The name of the default Budget. This name will be used to create the Budget in AWS and will be used in the<br>    alerts generated by the Budget. | `string` | `"Default Budget"` | no |
| <a name="input_company_address_line_1"></a> [company\_address\_line\_1](#input\_company\_address\_line\_1) | Company address, required for the primary contact. | `string` | n/a | yes |
| <a name="input_company_address_line_2"></a> [company\_address\_line\_2](#input\_company\_address\_line\_2) | Company address line 2 (optional), required for the primary contact. | `string` | `""` | no |
| <a name="input_company_city"></a> [company\_city](#input\_company\_city) | Company city, required for the primary contact. | `string` | n/a | yes |
| <a name="input_company_country_code"></a> [company\_country\_code](#input\_company\_country\_code) | Company country code, required for the primary contact. | `string` | n/a | yes |
| <a name="input_company_name"></a> [company\_name](#input\_company\_name) | Company name, required for the primary contact. | `string` | n/a | yes |
| <a name="input_company_postal_code"></a> [company\_postal\_code](#input\_company\_postal\_code) | Postal code or Zip code of the company, required for the primary contact. | `string` | n/a | yes |
| <a name="input_company_state_or_region"></a> [company\_state\_or\_region](#input\_company\_state\_or\_region) | Company State or Province or Region, required for the primary contact. | `string` | n/a | yes |
| <a name="input_cost_alerts_email_addresses"></a> [cost\_alerts\_email\_addresses](#input\_cost\_alerts\_email\_addresses) | List of email addresses to send notifications to. At least one email address must be set. | `list(string)` | `[]` | no |
| <a name="input_cost_allocation_tags"></a> [cost\_allocation\_tags](#input\_cost\_allocation\_tags) | Set of Cost Allocation tags to be used for cost allocation. These tags become available in Cost Explorer and make<br>    reporting much easier.<br>    The default set of cost allocation tags here is what is used by Apres modules:<br>    * environment: Name of the environment, used to differentiate instances, like Dev, Test, Prod, etc.<br>    * application: Overall application name.<br>    * component: Component of an application<br>    * owner: Owner of the resource, typically Engineering but could be something else.<br>    * managed-by: Name of the tool managing the resources, usually Terraform but could be something else. | `list(string)` | <pre>[<br>  "environment",<br>  "application",<br>  "component",<br>  "owner",<br>  "managed-by"<br>]</pre> | no |
| <a name="input_cost_anomaly_alert_on_dollars"></a> [cost\_anomaly\_alert\_on\_dollars](#input\_cost\_anomaly\_alert\_on\_dollars) | Alert if a Cost Anomaly is greater than or equal to this dollar amount. This condition will be combined with<br>    the anomaly\_alert\_on\_percentage condition using an AND operator. | `number` | `100` | no |
| <a name="input_cost_anomaly_alert_on_percentage"></a> [cost\_anomaly\_alert\_on\_percentage](#input\_cost\_anomaly\_alert\_on\_percentage) | Alert if a Cost Anomaly is greater than or equal to this percentage. This condition will be combined with<br>    the anomaly\_alert\_on\_dollars condition using an AND operator. Valid values can be more than 100%. | `number` | `10` | no |
| <a name="input_cost_anomaly_alerts_frequency"></a> [cost\_anomaly\_alerts\_frequency](#input\_cost\_anomaly\_alerts\_frequency) | Frequency of the cost\_anomaly alerts, one of DAILY, IMMEDIATE, or WEEKLY. Note that IMMEDIATE alerts are not supported for email<br>  subscriptions. If email addresses are supplied and frequency is set to IMMEDIATE, the email subscriptions will be<br>  set to DAILY. If email addresses are supplied and frequency is set to WEEKLY, the email subscriptions will be set to WEEKLY. | `string` | `"DAILY"` | no |
| <a name="input_enable_regions"></a> [enable\_regions](#input\_enable\_regions) | A map of regions to enable for the organization. This applies to regions introduced after March 20, 2019<br>    as the previous regions are enabled by default, and cannot be disabled. The default is to enable<br>    us-east-1 and us-east-2, it's actually a noop since they are already enabled.<br><br>    The key of the variable is the name of the account, and the value is a list of<br>    region names to enable in that account. If the region is not listed, it will not be enabled, with the<br>    caveat of the regions that are enabled by default.<br><br>    See the AWS Doc [Considerations before enabling and disabling Regions](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-regions.html?icmpid=docs_orgs_console#manage-acct-regions-considerations)<br>    for particulars on enabling or disabling regions.<br><br>    A combination of default and specific accounts may be used. In the following example all accounts<br>    will have us-east-1 and us-east-2 enabled, except for the account with the ID 123456789012 which will have<br>    four regions enabled.<pre>hcl<br>    module "organizations" {<br>      # ...<br>      enable_regions = {<br>        "default" = ["us-east-1", "us-east-2"],<br>        "123456789012"    = ["us-east-1", "us-west-2", "us-west-1", "ca-west-1"]<br>      }<br>    }</pre> | `map(list(string))` | <pre>{<br>  "default": [<br>    "us-east-1",<br>    "us-east-2"<br>  ]<br>}</pre> | no |
| <a name="input_msteams_channel_id"></a> [msteams\_channel\_id](#input\_msteams\_channel\_id) | The Microsoft Teams Channel ID for notifications.  The Channel Id is buried in the URL to the channel,<br>    and can be found in Teams using the "Get link to channel" menu option. A resulting URL might look like<br>    `https://teams.microsoft.com/l/channel/19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2/aws-security-hub-test?groupId=048113e8-d452-4921-95dd-be5f410e7aaf&tenantId=35591627-bdde-4d16-a221-bf72ffc20990`<br>    and the Channel ID is between the slashes after `channel`, in this case the Channel ID i<br>    is `19%3a8451e761b67a4416b47ac034d6d8cc5c%40thread.tacv2`.<br><br>    If left blank, MS Teams integration will not be enabled. | `string` | `""` | no |
| <a name="input_msteams_team_id"></a> [msteams\_team\_id](#input\_msteams\_team\_id) | The Microsoft Teams Team ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_msteams_tenant_id"></a> [msteams\_tenant\_id](#input\_msteams\_tenant\_id) | The Microsoft Teams Tenant ID for notifications. This is displayed in the AWS Console" | `string` | `""` | no |
| <a name="input_primary_contact_full_name"></a> [primary\_contact\_full\_name](#input\_primary\_contact\_full\_name) | Name of the primary contact, may be the same as given in the alternate contact info. | `string` | n/a | yes |
| <a name="input_primary_contact_phone_number"></a> [primary\_contact\_phone\_number](#input\_primary\_contact\_phone\_number) | Phone number of the primay contact, may be the same as given in the alternate contact info.<br>  See https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-update-contact-primary.html#manage-acct-update-contact-primary-requirements<br>  for requirements of format. | `string` | n/a | yes |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | The Slack channel ID for notifications. To find a channel ID, in Slack, right click on a channel<br>  and select "View channel details" and the Channel ID should be at the bottom, like C07S3JC2C0N. If left blank<br>  Slack integration will not be enabled. | `string` | `""` | no |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The Slack workspace ID for notifications,<br>  see https://slack.com/help/articles/221769328-Locate-your-Slack-URL-or-ID on how to find it. | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->