# Managed Grafana

This module deploys a centralized Managed Grafana meant to monitor all of your AWS accounts and regions. It should
be deployed to an AWS account separate from your workloads accounts, refered to as the "Observe" account.
This module depends on the
[aws_accounts_config_global](../aws_accounts_config_global/) module to be deployed to any AWS account which
should be monitored, typically all of your accounts.

This module depends on having GitHub access to the
[apresdev/lambda-grafana-configurator](https://github.com/apresdev/lambda-grafana-configurator/) repo. If
developing locally see [Local Development](#local-development).

## Warning!

The module creates a service account and an API token, which is used to backup the dashboards you create. The token
expires after 30 days (the maximum age it can be set to in Grafana) after which backups will fail.
The workaround is to deploy this stack at least once every 30 days.

In GitHub Actions, you can trigger the deploy using a [schedule trigger](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule),
in addition to changes from Pull Requests.  For example:

```yaml
name: my-deploy-workflow
on:
  schedule:
    # Uses cron syntax, runs 0400 UTC every Monday morning.
    - cron: '0 4 * * 1'
  pull_request:
    # ... the rest of your workflow
```

## Grafana Users and Groups Authentication

This module assumes that AWS IAM Identity Center is being used, and Grafana authentication uses the same
mechanism. There are six variables used to define access controls:
* `viewer_users` and `viewer_groups` - a list of users or groups who have viewer access.
* `editor_users` and `editor_groups` - a list of users or groups who have editor access.
* `admin_users` and `admin_groups` - a list of users or groups who have admin access.

When considering access levels, note, there is a price difference for tiers. You must define
at least one `admin` level user. See
[Amazon Managed Grafana pricing](https://aws.amazon.com/grafana/pricing/) for details.

All of the fields require IDs, there is no way to specify friendly names. To find the ID's,
login to the root AWS account that hosts your IAM Identity Center instance, navigate to the
user or group, and expand the "General Information" window, use the "Group ID" or "User ID"
field. An example ID is "e1dbb7c0-a1d2-309b-7ef5-174ad9a02d63".

## Configuring Grafana Automatically with The Configurator

The module deploys a Lambda to configure Grafana, called the Configurator.

While there is a [Grafana Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs),
it cannot be used in this context without violating good security.
The authentication to the Grafana API depends on an API Token hardcoded in the terraform provider section,
which has two major problems:
1. The provider section cannot be generated dynamically, so there is no way to create the token using
   the AWS provider, populating the Grafana provider, and then configuring Grafana.
2. In any Continuous Deployment flow, the API token would have to be either commited to source, or
   requires a bootstrap-type script to download it.

Instead we created the Configurator [lambda-grafana-configurator](https://github.com/apresdev/lambda-grafana-configurator/)
which will manage Grafana.

This grafana_managed module and Configurator work together as follows:
1. The module creates a Grafana API token at apply time and stores it in AWS Secrets Manager.
3. The module creates the Configurator Lambda.
4. The module invokes the Lambda and waits for the response. If the Lambda fails, the deploy will also fail.
5. The Configurator will also run as a scheduled lambda, every hour.

The Configurator also does the following, explained in more detail in the next sections:
* Manage CloudWatch data sources in Grafana, based on the `accounts` passed in as variables to this module.
* Provision the Apres dashboards included in this module, see
  [Configurator and Provisioning Dashboards](#configurator-and-provisioning-dashboards)
* Provision any dashboards provided in the `custom_dashboards` variable.
* Create Grafana Alerts for any CloudWatch alarms created with the [cloudwatch_alarm](../cloudwatch_alarm/) module.
* Backup all non-provisioned dashboards to S3.

### Configurator and Grafana AWS Permissions

Both the Configurator Lambda and Grafana uses a set of permissions created in the
[aws_accounts_config_global](../aws_accounts_config_global) module to access resources in all the configured
AWS accounts. The [aws_accounts_config_global](../aws_accounts_config_global) is deployed
with the `observe_account_id` set to the account where this module is deployed. That module
creates two roles with trust relationships to the observe account:
  * `ApresGrafanaConfiguratorCrossAccountAccess` granting the Configurator read-only access to CloudWatch
  * `ApresGrafanaCrossAccountAccess` granting Grafana read-only access to CloudWatch

### Configurator and CloudWatch Data Sources

The Configurator will create a CloudWatch datasource in Grafana for every account passed into the
`accounts` variable. The name of the data source will be the name of the account with the account ID, for example
_Dev (123456789012)_. The datasource will be recreated if it is accidentally deleted.

### Configurator and Provisioning Dashboards

Two sets of dashboards will be provisioned:
* Apres dashboards: these dashboards are uploaded and stored in a Grafana folder named "Apres". You should
  _not_ edit those dashboards directly (but there is nothing preventing you from doing so). If you wish to
  make changes, duplicate the dashboard and create a new version of it. If a newer version of an Apres
  dashboard is uploaded by this module, it will overwrite your changes. The dashboards are embedded in
  [this module](./dashboards/).
* Custom dashboards: these are provided in the `custom_dashboards` variable, and will be uploaded to the
  folder name specified in the `custom_dashboard_folder_name` variable. Similar to the Apres dashboards, these
  will be overwritten.

In both cases the S3 bucket created by the module will have folders using the same name, the module uploads the
dashboard JSON to the S3 bucket, and the Configurator uses S3 as the source to populate Grafana.

### Configurator and Alarms and Alerts

The Configurator translates CloudWatch Alarms to Grafana Alerts. It uses roughly the following algorithm:
* For each account and region combination give in `accounts` and `regions`
  * Look for Alarms with the tags `severity`, `runbook` and `source=apres_cloudwatch_alarm_module`. If one is found:
    * Create or Update a Grafana Alert using the CloudWatch Alarm as a template
    * Place the Alert in the Apres folder
    * Convert Tags to Labels.
    * Add `account-id`, `account-name` and `region` as Labels.

If an alarm is created using the [cloudwatch_alarm](../cloudwatch_alarm/) module, it will automatically show
up as a Grafana Alert after the Configurator's next hourly run.

See [Notifying on Alarms](#notifying-on-alarms) for details on notifications.

### Configurator and Dashboard Backups

The Configurator backs up all non-provisioned dashboards to the S3 bucket, in the `backups/` prefix. The
dashboards are stored using their UID's as filenames.

## Notifying on Alerts

Setting up notifications on the alarms is left as an exercise to the reader, documented at
[Alerts in Grafana version 10](https://docs.aws.amazon.com/grafana/latest/userguide/v10-alerts.html). This module
uses Grafana Alerting, not the legacy alerts that will be removed in Grafana version 11.

Unfortunately the default Grafana configuration comes with a broken SNS contact point, and the
Configurator cannot fix it. This module creates the following resource:
* An SNS topic and permissions for Grafana to write to it, the ARN is available in the
  output `sns_notifications_topic_arn`.
* A Grafana contact point named `Default SNS Contact Point` configured to write the SNS topic.

Apres does not recommend using email in subscriptions for two reasons:
1. In a complex environment emails get lost or ignored, and have no escalation path during non-working hours.
2. The emails are complex to understand, without any way to change them.

Instead, use a service like PagerDuty or VictorOps.

With those caveats, if you wish to send notifications via SNS to email, you will need to:
1. Specify the email address(es) in the `alert_email_addresses` variable.
2. A subscription confirmation email will be sent to the email address(es), you will need to confirm them.
3. By default no alerts will be sent, you will need to setup a Notification Policy to filter the alerts you
   want to, using the Contact point `Default SNS Contact Point`.

## Dashboards and Accounts and Regions

By default a Grafana dashboard will have the datasource hardcoded, which you do not want for a
provisioned dashboard. Instead you will want a dropdown for both the datasource (account) and region.
See the [nat-instance dashboard](./dashboards/nat-instance.json) for how this is done using two variables
for AWS Account and Region.

## AWS Permissions for Deployment

The following AWS Permissions are required to deploy this module. Replace the following variables:
* `${AWS::AccountId}` with the 12 digit AWS Account ID this module is deployed to
* `${AWS::Region}` with the region this module is deployed to, like `us-east-2`
* `${environment}` with the `environment` variable passed into this module
* `${name}` with the `name` variable passed into this module

```json
{
  "Effect": "Allow",
  "Action": [
    "grafana:*",
    "ssm:*",
    "kms:ListAliases",
    "logs:DescribeLogGroups",
  ],
  "Resource": "*"
},
{
  "Sid": "AllowManagedGrafanaWithSSO",
  "Effect": "Allow",
  "Action:" [
    "sso:*"
  ],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": [
    "iam:*"
  ],
  "Resource": [
    "arn:aws:iam::${AWS::AccountId}:role/${environment}-${name}-*",
    "arn:aws:iam::${AWS::AccountId}:role/ApresGrafanaCrossAccountAccess"
  ]
},
{
  "Effect": "Allow",
  "Action": [
    "signer:GetSigningProfile",
    "signer:StartSigningJob"
  ],
  "Resource": "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-profiles/*"
},
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket",
    "s3:GetBucketWebsite",
    "s3:ListBucketVersions"
  ],
  "Resource": "arn:aws:s3:::${AWS::AccountId}-${lambda_regional_environment}-${AWS::Region}-lambda-artifacts"
},
{
  "Effect": "Allow",
  "Action": [
    "s3:*"
  ],
  "Resource": [
    "arn:aws:s3:::${AWS::AccountId}-${environment}-${AWS::Region}-grafana-dashboards",
    "arn:aws:s3:::${AWS::AccountId}-${environment}-${AWS::Region}-grafana-dashboards/*"
  ]
}
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
    "sns:*"
  ],
  "Resource": "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:${environment}-${name}-alerts"
}

```

## Local Development

The unit tests are setup to run in the Apres Test account, with permissions setup by a
separate repository. To test locally, change the account structure in
[./tests/grafana_test.go](./tests/grafana_test.go) to just the Sandbox account, and then
run the tests as usual.

If running locally you need to create a Personal Access Token (PAT) and set the GITHUB_TOKEN environment
variable with the PAT, or the deploy will fail. See the
[Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
document for details.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.86.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 6.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.98.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |
| <a name="provider_github"></a> [github](#provider\_github) | 6.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |
| <a name="module_dashboards-bucket"></a> [dashboards-bucket](#module\_dashboards-bucket) | git@github.com:apresdev/apres-terraform.git//modules/aws/s3 | rel/s3/4.2.0 |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | git@github.com:apresdev/apres-terraform.git//modules/aws/lambda | rel/lambda/1.1.2 |
| <a name="module_lambda_scheduler"></a> [lambda\_scheduler](#module\_lambda\_scheduler) | git@github.com:apresdev/apres-terraform.git//modules/aws/lambda_scheduler | rel/lambda_scheduler/0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_grafana_role_association.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_role_association) | resource |
| [aws_grafana_role_association.editor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_role_association) | resource |
| [aws_grafana_role_association.viewer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_role_association) | resource |
| [aws_grafana_workspace.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_workspace) | resource |
| [aws_grafana_workspace_service_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_workspace_service_account) | resource |
| [aws_grafana_workspace_service_account_token.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_workspace_service_account_token) | resource |
| [aws_iam_policy.grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.assume_remote_accounts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_invocation.grafana_configurator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) | resource |
| [aws_s3_bucket_lifecycle_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_object.custom_dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.grafana_dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_sns_topic.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_ssm_parameter.grafana_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.grafana_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [external_external.artifact_download](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [github_release.lambda](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accounts"></a> [accounts](#input\_accounts) | AWS Account IDs that Grafana should have access to. The key is the display name and will<br/>    be used as when creating the data source, in practice this should match the account name. | `map(string)` | n/a | yes |
| <a name="input_admin_groups"></a> [admin\_groups](#input\_admin\_groups) | List of Group IDs that should have ADMIN access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication). | `list(string)` | `[]` | no |
| <a name="input_admin_users"></a> [admin\_users](#input\_admin\_users) | List of User IDs that should have ADMIN access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication). | `list(string)` | `[]` | no |
| <a name="input_alert_email_addresses"></a> [alert\_email\_addresses](#input\_alert\_email\_addresses) | A list of email addresses to subscribe to the default Grafana Alerts SNS Topic.<br/><br/>    NOTE: This does not automatically send all alerts to these email addresses, there are two<br/>    manual steps to take, see the [Notifying on Alerts](#notifying-on-alerts) section for more information. | `list(string)` | `[]` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | `"Observability"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | `"Grafana"` | no |
| <a name="input_custom_cloudwatch_metrics_namespaces"></a> [custom\_cloudwatch\_metrics\_namespaces](#input\_custom\_cloudwatch\_metrics\_namespaces) | List of custom namespaces in CloudWatch to be added to the CloudWatch data sources.<br/>    If they are not added, the dashboards will not be able to search for metrics in these namespaces.<br/>    The standard Apres namespaces will be added automatically. | `list(string)` | `[]` | no |
| <a name="input_custom_dashboard_folder_name"></a> [custom\_dashboard\_folder\_name](#input\_custom\_dashboard\_folder\_name) | Name of the folder where custom dashboards will be uploaded. This will be used both in S3<br/>    as the intermediary storage, and in Grafana as the folder name." | `string` | `"Custom"` | no |
| <a name="input_custom_dashboards"></a> [custom\_dashboards](#input\_custom\_dashboards) | List of custom dashboards to be added to Grafana. The key is the display name and the value is the<br/>    path to the file containing the dashboard. JSON. The dashboards will be uploaded to the folder<br/>    name specified in `custom_dashboard_folder_name`. | `map(string)` | `{}` | no |
| <a name="input_editor_groups"></a> [editor\_groups](#input\_editor\_groups) | List of Group IDs that should have EDITOR access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication). | `list(string)` | `[]` | no |
| <a name="input_editor_users"></a> [editor\_users](#input\_editor\_users) | List of User IDs that should have EDITOR access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication). | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | `"Global"` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | List of regions in which Grafana should look for CloudWatch alarms.<br/>    The current region will be added to the list if it is not already present. | `list(string)` | n/a | yes |
| <a name="input_viewer_groups"></a> [viewer\_groups](#input\_viewer\_groups) | List of Group IDs that should have VIEWER access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication). | `list(string)` | `[]` | no |
| <a name="input_viewer_users"></a> [viewer\_users](#input\_viewer\_users) | List of User IDs that should have VIEWER access to Grafana, see [Users and Groups](#grafana-users-and-groups-authentication). | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_grafana_arn"></a> [grafana\_arn](#output\_grafana\_arn) | The ARN of the Grafana workspace |
| <a name="output_grafana_url"></a> [grafana\_url](#output\_grafana\_url) | The URL of the Grafana workspace |
| <a name="output_grafana_version"></a> [grafana\_version](#output\_grafana\_version) | The version of the Grafana workspace |
| <a name="output_notifications_sns_topic_arn"></a> [notifications\_sns\_topic\_arn](#output\_notifications\_sns\_topic\_arn) | SNS Topic ARN to which notifications can be sent |
<!-- END_TF_DOCS -->