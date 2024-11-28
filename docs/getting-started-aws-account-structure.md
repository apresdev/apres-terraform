# Recommended AWS Account Structure

Apres recommends the following AWS Account structure in AWS Organizations for your organization.
```
Org Root
    - root-aws-account
    - Infrastructure OU
        - artifacts account
        - deploy account
        - observe account
    - Sandbox OU
        - sandbox account
    - Security OU
        - audit account
        - log archive account
    - Workloads OU
        - Dev OU
             - dev account
        - Test OU
             - test account
        - Prod OU
             - prod account
```

## Root Account

The root account is the AWS account you first created, also known as the Management account in AWS Control Tower documentation. You should _never_ deploy workloads to this account! The root account is used for the following (Note it is possible to delegate some of the following activities to other accounts):

* Consolidated billing - the billing for all accounts is rolled up into the root account
* Budget - create budgets and trigger budget alerts if projected or actual spend is over the budgeted amount
* Cost Anomaly Detection - trigger alerts if cost anomalies are detected
* AWS Control Tower core configuration
* Integration with your IDP such as Google Workspace or Microsoft 365

## Audit Account

The Audit account is created by AWS Control Tower, and is meant to be used by your organizations's Security and Compliance
teams. AWS GuardDuty events roll up into the Audit account, among other events.

See [AWS Documentation](https://docs.aws.amazon.com/controltower/latest/userguide/accounts.html) for more details.

## Log Archive Account

The Log Archive account is created by AWS Control Tower, and is meant to be a single point of read-only storage for all
security events.

See [AWS Documentation](https://docs.aws.amazon.com/controltower/latest/userguide/accounts.html) for more details.

## Artifacts Account

The artifacts account is mean to be a single point to store artifacts that are built by your Continuous Integration
(CI) pipeline, that are to be shared to the workload accounts.

For example, if your CI pipeline builds a docker container, it should be pushed to an ECR repository in your Artifacts
account, so it can be re-used in all your workload accounts. The goal is to build an artifact once, publish it, and then re-use it where needed. Examples:
* Docker images pushed to ECR
* AMI images pushed to EC2 (not yet supported by Apres Foundations)
* Binaries published to S3 (not yet supported by Apres Foundations)

## Deploy Account

The Deploy account is to host any Continuous Integration or Continuous Deployment (CI/CD) activities. At time of writing
the Apres Foundations modules do not use the Deploy account.

## Observe Account

The Observe account is to host a central Managed Grafana instance, used to view metrics across all accounts, and
used to alert on any alarms created in the accounts.

## Sandbox Account

While not strictly required, having a Sandbox account is highly beneficial for your organization, as a place to try things out without risk of breaking anything else.

## Workload Accounts

The workload accounts are where your workloads, such as API's, CloudFront deployments, backend services in ECS or Lambda, are running that make up the core of your business. Apres strongly recommends splitting up Dev, Test and Production into
separate accounts and OU's. There are several good reasons for doing so:
1. The AWS Foundational Technical Review, along with SOC2 and ISO27001 certification, require having strong boundaries between your dev/test and production workloads.
2. Splitting the workloads into separate accounts significantly reduces the risk of development activities causing problems to your production environment.