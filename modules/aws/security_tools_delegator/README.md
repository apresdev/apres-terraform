# Setup the Management Account

This module must be applied to the management account, and just delegates the management of the security tools
to a different account. Control Tower refers to this account as the Audit account.

The [security_tools](../security_tools/README.md) module should then be applied to the Audit account.

AWS Organizations and regions are not straight forward.
* AWS Organizations is a global service, only needs to be configured in the primary region.
* Security Hub is a global service, and should only be configured in the primary region.
* GuardDuty is a regional service and should be configured in all active regions.

For that reason, this module should be applied to every active region. It uses the `primary_region` variable to
determine which services to delegate.

# Prerequisites

## AWS Organizations

Enable AWS Organizations. See [the docs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html) on how to enable AWS Organizations.

## AWS Control Tower

Enable AWS Control Tower. Limit the set of enabled regions to only the regions you _really_ need. See [the docs](https://docs.aws.amazon.com/controltower/latest/userguide/setting-up.html) on how to enable Control Tower.

# AWS IAM Permissions

The following permissions are required to use this module, shown in CloudFormation yaml format:

```yaml
  - Effect: Allow
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_organization_admin_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_securityhub_organization_admin_account.securityhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | The AWS account ID of the Audit account, which will be used to delegate configuration of the Security Tools | `string` | n/a | yes |
| <a name="input_primary_region"></a> [primary\_region](#input\_primary\_region) | The primary region for the security tools. This is used to determine which services need to be delegated<br>  and which not based on the region where this is deployed. For example. GuardDuty needs to be delegated in<br>  every region, but Security Hub only in the primary region. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->