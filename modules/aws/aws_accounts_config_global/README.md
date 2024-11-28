# Global account configuration for AWS Accounts

This module is meant to be applied to every AWS account in your organization, but only in one region.

The module sets up:
* the IAM Password Policy
* Two IAM roles for cross-account monitoring through Grafana:
    * `ApresGrafanaCrossAccountAccess` - grants Grafana in the `monitoring_account_id` access to view
       CloudWatch metrics and logs in this account
    * `ApresGrafanaConfiguratorCrossAccountAccess` - grants Lambda in the `monitoring_account_id` access
      to view CloudWatch to configure alarms.

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
    "Resource": "*"
},
{
    "Effect": "Allow",
    "Action": [
        "iam:*"
    ],
    "Resources": [
        "arn:aws:iam::${AWS::AccountId}:role/Apres*"
    ]
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.75.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_account_password_policy.strict](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |
| [aws_iam_role.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.cloudwatch_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_observe_account_id"></a> [observe\_account\_id](#input\_observe\_account\_id) | The AWS account ID of the monitoring account. This account will be granted access to<br>        view CloudWatch metrics, alarms and logs. | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->