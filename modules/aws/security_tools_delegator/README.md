# Setup the Management Account

This module must be applied to the management account, and just delegates the management of the security tools
to a different account. Control Tower refers to this account as the Audit account.

The [security_tools](../security_tools/README.md) module should then be applied to the Audit account.

# Prerequisites

## AWS Organizations

Enable AWS Organizations. See [the docs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html) on how to enable AWS Organizations.

## AWS Control Tower

Enable AWS Control Tower. Limit the set of enabled regions to only the regions you _really_ need. See [the docs](https://docs.aws.amazon.com/controltower/latest/userguide/setting-up.html) on how to enable Control Tower.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_organization_admin_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_securityhub_organization_admin_account.securityhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | The AWS account ID of the Audit account, which will be used to delegate configuration of the Security Tools | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->