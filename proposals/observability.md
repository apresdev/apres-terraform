# Observability Proposal

Current as of November 5, 2024

This proposal includes the mechanism for:
* publishing dashboards created/exposed by Apres Terraform modules
* making metrics and logs visible
* publishing alarms to common communication methods

## Current design
The current design is:
* Use CloudWatch Dashboards, created by the deploy of a module in this repo.
* Use CloudWatch Alarms to notify when something needs attention
  (see https://github.com/apresdev/apres-terraform/pull/262/ for details)
* Use AWS ChatBot for notification to Slack and/or Microsoft Teams

The advantages of this approach:
* The metrics, alarms and dashboards are deployed in the same Terraform stack as the resources.
* The alarms can have different thresholds depending on the region or account.

There are several problems:
* A CloudWatch dashboard costs $3/dashboard/month, which will quickly become expensive as accounts/regions expand.
* There is no way to view all regions or accounts or some combination thereof in one dashboard.
* AWS Chatbot only supports Slack and Teams. Clients will eventually want PagerDuty or OpsGenie, etc.
* There is no way to aggregate alerts - since Slack channel integrations are per AWS Account and region, this will result
  in a proliferation of Slack channels. For example `#aws-prod-us-east-2` and `#aws-prod-us-west-2` for just to regions
  in the internal prod account... in testing the author has twelve separate channels.
* AWS Chatbot, and the Terraform provider used to configure it, are both buggy.

The last problem, the bugginess, is the real driver for this document. Chatbot is relatively new but not well supported, and
we've run into two issues:
* Cannot create more than one Teams channel per account [Bug](https://github.com/hashicorp/terraform-provider-aws/issues/38943)
* One of our internal accounts is in a strange state - there are no Slack channels defined, but creating one consistently fails
  with an error that it already exists.

Those two problems are solveable, but leave the maturity of Chatbot in doubt, and led to a rethinking/redesign, which follows.

## Requirements

The author wishes to:
* Provide a single place to view the health of all services across all regions and accounts.
* Provide a consistent way to alert on issues, with support for PagerDuty.
* Continue to deploy alarms along with the Terraform stack - the alarms and thresholds should be configured with the
  deployed stack. For example, if deploying an ECS stack using the [ecs](../modules/aws/ecs) module,
  the alarm and its thresholds should be defined in that stack.
* If possible the solution should work with backstage.io in preparation for layer 2.

## Proposal

### Dashboard with Grafana

Use AWS Managed Grafana in a separate AWS account, with permissions setup to pull metrics and logs from all other
AWS accounts and regions. This [article](https://pcg.io/insights/aws-managed-grafana-for-one-or-multiple-aws-organizations/)
explains how to setup the permissions to allow this.

Grafana has become the defacto industry standard, and from experience is fantastic tool. We will use
[AWS Managed Grafana](https://docs.aws.amazon.com/grafana/) since it integrates neatly with the existing Identity provider,
CloudTrail, and other AWS services. It is not free, the cost is $9/month per editor and $4/month per viewer, but only
if the users login and use the tool.

Using AWS Managed Grafana does not prevent a customer from using their own Grafana instance later, and migration of
dashboards and alerting configuration is simple.

The proposed Grafana instance will be able to view metrics and logs from CloudWatch in all regions.

### Alarms with Grafana Alerting

Grafana Alerting is a mature alerting engine, with support for alerting via Slack, PagerDuty, OpsGenie, VictorOps, and SNS.
Notably, Microsoft Teams is missing in Grafana 10.4, the current AWS version. Teams is supported in Grafana 11. If Teams
integration is required, we would either wait for AWS to support Grafana 11, or use an SNS target with a custom Lambda.

### Alarm Definition with Lambda

The requirement for a single central dashboard and locally deployed alarms conflicts - there is no way for a Terraform
stack deploying resources to AWS account "A" to also deploy an alarm configuration to AWS account "B".

We propose the following:
* Use a modified version of the proposed [CloudWatch Alarm module](https://github.com/apresdev/apres-terraform/pull/262/), to
  create the CloudWatch Alarm in the account/region where the stack is being deployed. The alarm will not
  have any actions defined.
* A Lambda with appropriate permissions will periodically scan all AWS accounts in the org looking for CloudWatch Alarms with
  either a specific tag or name pattern. (Note: AutoScaling also uses CloudWatch Alarms, those will not be populated in
  Grafana.) The Lambda will populate the single Grafana instance converting CloudWatch Alarms
  into Grafana Alert rules, and remove Alert rules for which the corresponding CloudWatch Alarm was removed.

Labels will be set on the Alert rules to match the tags on the original CloudWatch Alarm, and labels will be included
for the AWS account name, id and region.

Notification rules can then be setup by the client to use the labels to act differently depending on the alarm.
For example:
* Alert via Pagerduty if alert is from account `prod` and region `us-east-2` and severity is `SEV1`.
* Alert via Slack if alert is from any account and severity is SEV2.

The advantages of this approach:
* If the client looks at CloudWatch in an account, the alarms will appear in an obvious, expected place.
* This approach allows for deploying unique thresholds for a stack depending on the region and account.

The disadvantages are:
* The Lambda will be reasonably complex, and need to be maintained by Apres.
* CloudWatch Alarms cost $0.10 per month, while not expensive they are not free either.

### Grafana Dashboards

Two Apres modules currently deploy CloudWatch dashboards ([vpc](../modules/aws/vpc/) and [ecs](../modules/aws/ecs/))
to the account/region where those modules are deployed.

We propose switching to use Grafana dashboards. Versioning immediately becomes a challenge. Currently the CloudWatch
dashboards are deployed along with the stack, and if the stack changes, the dashboard deployed will match. In the
proposed scheme that will not work, as for example the [ecs](../modules/aws/ecs/) module may have several versions
running across a client's accounts and regions.

To address this we have several options:
1. A Grafana dashboard can be represented in JSON. When a stack deploys, publish the corresponding dashboard to
   a local S3 bucket. A Lambda, similar to the one proposed in [Alarm Definition with Lambda](#alarm-definition-with-lambda)
   will periodically retrieve and load the dashboards into the single Grafana instance, with the version of the module
   in the dashboard name.
2. Dashboards will be kept separately in the Grafana module, and the module authors will need to keep the dashboards
   up to date with any changes, as well as keep the major version numbers in the dashboard name.

The second option is simpler to manage, and we propose using that mechanism.