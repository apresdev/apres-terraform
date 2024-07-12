# Global account configuration for AWS Accounts

This module is meant to be applied to every AWS account in your organization, but only in one region. For now the only
resource is setting the IAM Password Policy but more are planned.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

```json
{
    "Effect": "Allow",
    "Action": [
        "iam:DeleteAccountPasswordPolicy",
        "iam:GetAccountPasswordPolicy",
        "iam:UpdateAccountPasswordPolicy"
    ],
    "Resource: "*"
}
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_account_password_policy.strict](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->