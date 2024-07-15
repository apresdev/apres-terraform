# Getting Started with Apres - Part 1 - AWS Bootstrap

## Table of Contents

1. [Create Email Address(es) for your AWS Accounts](#1-create-email-addresses-for-your-aws-accounts)
2. [Create the Root AWS Account](#2-create-the-root-aws-account)
3. [Secure the Root credentials with MFA](#3-secure-the-root-credentials-with-mfa)
4. [Select the primary (home) region](#4-select-the-primary-home-region)
5. [Enable IAM Identity Center and create a user account](#5-enable-iam-identity-center-and-create-a-user-account)
6. [Create an AWS Organization](#6-create-an-aws-organization)
7. [Configure AWS Control Tower](#7-configure-aws-control-tower)
8. [Enable IAM access to billing](#8-enable-iam-access-to-billing)
9. [Enable Integration to your Identity Provider](#9-enable-integration-to-your-identity-provider)

## 1. Create Email Address(es) for your AWS Accounts

Each AWS account requires a unique email address, and you will be creating multiple AWS accounts. Apres
recommends creating a single distribution list and the using the `+` syntax for each account. For example:
* `aws@yourdomain.com` could be the distribution list name, this email address is used for the `root` account.
* `aws+audit@yourdomain.com` is the email address for the `audit` account
* `aws+logarchive@yourdomain.com` is the email address for the `log archive` account

Both Google Workspace and Microsoft 365 support the `+` syntax.

Instructions on how to create a distribution list:
* [Google Workspace instructions](https://support.google.com/a/answer/9400082?hl=en)
* [Microsoft 365 instructions](https://learn.microsoft.com/en-us/microsoft-365/admin/setup/create-distribution-lists?view=o365-worldwide)

Remember to add yourself to the distribution list, as you will need to receive emails in the next step!

## 2. Create the Root AWS Account

Create the Root AWS account. This will be used for:
* Billing
* Integration with your organization's authentication (Google Workspace, Microsoft 365, etc)
* The root account for AWS Organization

Follow the [Create a standalone AWS account](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-creating.html) instructions, using the email address created above. You will need:

* Access to your email, a verification code will be sent
* Create a strong password, preferably using 1Password or another password manager.
* A valid credit card

## 3. Secure the Root credentials with MFA

The email address and password you created in step 2 are critical to your organization and should be treated
carefully. If anyone outside your organization gets the password, they can cause an inordinate amount of havoc
for your organization. Enabling Multi-Factor Authentication (MFA) for the Root account means attackers will
not be able to login by guessing or obtaining your password.

You have three options for enabling MFA, with detailed explanation in [this doc](https://docs.aws.amazon.com/IAM/latest/UserGuide/avail-mfa-types-for-root.html).

1. Enabling passkey or security key
2. Enabling a virtual MFA device
3. Enabling a hardware TOPT token

Which one you enable depends on your organization. A few key points when making the decision
* Only trusted individuals should have access to the MFA device, it should not be shared with everyone.
* Physical devices are very secure but depend on you having a secure location to store it. Most small organizations do not have this.

## 4. Select the primary (home) region

Several of the next few steps have dependencies on selecting a primary region, and it is very difficult to change later on.  Your workloads can still be deployed in other regions, but the resources in steps 5 and 7 MUST be in the same region.
Apres recommends `us-east-2` (Ohio) as the default, and never using `us-east-1`.

## 5. Enable IAM Identity Center and create a user account

It is critical that you do not use the Root user account for day-to-day activities. For now you will
enable IAM Identity center with the default directory, and integration with your identity provider can
come later.

In the region you selected in Step 4, follow the [Enabling AWS IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/get-set-up-for-idc.html) steps.

Create a user account for yourself following [Configure user access with the default IAM Identity Center directory](https://docs.aws.amazon.com/singlesignon/latest/userguide/quick-start-default-idc.html) steps. Apres recommends using the same naming standard for user accounts as your organization's email uses. User accounts must _never_ be shared, and must be traceable to an individual in your organization.

Login to AWS using the new user account you just created, and use that account for all remaining step
unless explicitly stated.

## 6. Create an AWS Organization

Follow the AWS documentation:
1. [Create an organization](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_create.html)
1. [Enabling all features in your organization](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html)

If you have existing accounts you wish to add to your new AWS Organization, follow the [Inviting an AWS account to join your organization](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html) steps.

## 7. Configure AWS Control Tower

AWS Control Tower is a way to govern a multi-account environment. Ensure you are in the home region selected in Step 4! Follow the steps [Getting started with the AWS Control Tower from the console](https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-from-console.html) to enable Control Tower.

Notes:
* Control Tower will setup two accounts `log archive` and `audit`. Apres recommends using the defaults for these.
* Step 2a is to review and select AWS regions. Apres recommends only enabling regions where you know your workloads will be deployed and disabling the rest. That will both prevent accidental deploys into those regions, and save cost on some tooling in the future.

### Control Tower VPCs

Control Tower will by default create VPCs in your new accounts in each of the enabled regions. There are three problems
with the Control Tower VPC's:
1. They use the NAT Gateways, which are extremely expensive to run.
2. They only have two subnets by default, which means any workload deployed there can only run in two Availability
   Zones instead of the recommended three.
3. The VPC's in all accounts and regions share the same CIDR (IP Address) range, which will cause problems if any
   connections are required between VPC's (Peering or Transit Gateway)

Apres recommends disabling the Control Tower VPC's. The way to do so is not straight forward:
1. In the AWS Console in the root account, navigate tot he AWS Control Tower service.
2. Select the "Account Factory" link on the left.
3. Under "Network Configuration" click the "Edit" button.
4. In the "Maximum number of private subnets" dropdown, select `0`.
5. Click the "Save" button at the bottom. VPC creation has now been disabled.

### Configure the Organization Unit and create AWS Accounts.

Once Control Tower is setup, Apres recommends following AWS's recommended Organizational Units (OUs) structure,
[outlined here](https://docs.aws.amazon.com/controltower/latest/userguide/aws-multi-account-landing-zone.html#guidelines-for-multi-account-setup), namely:

* Security - this OU is created by default, where the `audit` and `log archive` accounts will exist.
* Infrastructure - this is where a shared Artifacts account should exist (AWS ECR, any AMI's, etc), CI/CD tools will exist here, etc.
* Sandbox - meant for software development, those "oh let's try something".
* Workloads - this is where the accounts that run your workloads will live

Create the new OU's following the [Create a new OU](https://docs.aws.amazon.com/controltower/latest/userguide/create-new-ou.html) steps.

Create new AWS accounts in the OU's following the [Provision accounts with the AWS Service Catalog Account Factory](https://docs.aws.amazon.com/controltower/latest/userguide/provision-as-end-user.html) steps. When asked for email
addresses, use the email address(es) created in [Step 1](#1-create-email-addresses-for-your-aws-accounts).

A typical recommended OU structure, shown with AWS accounts and associated email addresses looks as follows, with
a detailed explanation of the recommended accounts documented in [Recommended AWS Account Structure](./getting-started-aws-account-structure.md):

```
Org Root
    - root-aws-account - aws@yourdomain.com
    - Infrastructure OU
        - artifacts - aws+artifacts@yourdomain.com
        - deploy - aws+deploy@yourdomain.com
    - Sandbox OU
        - sandbox - aws+sandbox@yourdomain.com
    - Security OU
        - audit - aws+audit@yourdomain.com
        - log archive - aws+logarchive@yourdomain.com
    - Workloads OU
        - Dev OU
             - dev - aws+dev@yourdomain.com
        - Test OU
             - test - aws+test@yourdomain.com
        - Prod OU
             - prod - aws+prod@yourdomain.com
```

See [AWS Account Structure](./getting-started-aws-account-structure.md) for further discussion on account structure.

## 8. Enable IAM access to billing

By default access to the billing information, including Cost Explorer used to determine where your spend is,
is not enabled for non-root users, meaning you will not be able see any cost analysis or bills unless you login
as the root user. To fix that, as the root user, follow the [Granting access to your billing information and tools](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/control-access-billing.html#grantaccess) steps.

## 9. Enable Integration to your Identity Provider

Linking your new AWS Organization to your Identity Provider (IDP), such as Google Workspace or Microsoft 365, is key to securing your accounts for a few reasons:
1. Access to AWS can be granted and revoked in one place, in your IDP.
1. Onboarding, and more critically off-boarding, are managed in one place.
1. MFA can be enforced in one place instead of two.

This setup is highly dependant on your organization's IDP. Both AWS and the major IDPs have documented the process, with AWS's documents [here](https://docs.aws.amazon.com/singlesignon/latest/userguide/tutorials.html). The process will take 2-3 hours to complete, and requires privileged access to the IDP, and root user access to AWS. The Apres team has experience with both Google Workspace and Microsoft 365 and can help with the integration.

## Next Steps

Continue to [Getting Started Part 2](./getting-started-part-2-apres-foundations.md)