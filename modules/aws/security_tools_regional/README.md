# Apres AWS Region-specific Security Tools configuration

This module configures the region-specific security tools. Services such as GuardDuty and Inspector
are deployed per-region and thus require a pre-region deployment.

This module expects that the [security_tools_delegator](../security_tools_delegator/README.md) module
has been applied to the root account in all active regions.

This module sets up:
* Amazon GuardDuty publishing to Security Hub
* Amazon Inspector publishing to Security Hub

##  Amazon GuardDuty and AWS Organizations

AWS Organizations can setup GuardDuty in the audit account, but it is unclear how and in what regions. There is
a possibility the detector exists in the primary region after the `security_tools_delegator` module is deployed
to the root account. If that is the case, you will need to import the detector using the following steps:

1. Use the command `aws guardduty list-detectors` to get the detector ID for the region and account. Example output
   is as follows:
   ```json
   {
      "DetectorIds": [
        "bac76941540ffef6b96ffc7fe8e21234"
      ]
   }
   ```
2. Using the example above, import the detector with `tofu import aws_guardduty_detector.default bac76941540ffef6b96ffc7fe8e21234`

## Amazon Inspector

See [Automated scan types in Amazon Inspector](https://docs.aws.amazon.com/inspector/latest/user/scanning-resources.html)
for details on what the different scan types mean. By default all scan types are enabled.

## Future enhancements
1. Other region-specific services such as Detective may be added in future versions.
2. Add support to export GuardDuty events to S3. See
   [Export findings](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_exportfindings.html)

## Prerequisites

### Delegate Management

Run the [security_tools_delegator](../security_tools_delegator/README.md) module against the management
account of your organization, in all activer regions. This sets up the delegation for the services
that this module configures, and is required.

## AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed.

```json
{
  "Action": [
     "guardduty:*",
     "inspector2:*"
  ],
  "Resource": "*"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.80.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_detector.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_organization_configuration_feature.eks_runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_inspector2_enabler.members](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_inspector2_enabler.self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
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
| <a name="input_inspector_enable_ec2_scanning"></a> [inspector\_enable\_ec2\_scanning](#input\_inspector\_enable\_ec2\_scanning) | Enable Inspector to scan EC2 instances | `bool` | `true` | no |
| <a name="input_inspector_enable_ecr_scanning"></a> [inspector\_enable\_ecr\_scanning](#input\_inspector\_enable\_ecr\_scanning) | Enable Inspector to scan ECR repositories | `bool` | `true` | no |
| <a name="input_inspector_enable_lambda_code_scanning"></a> [inspector\_enable\_lambda\_code\_scanning](#input\_inspector\_enable\_lambda\_code\_scanning) | Enable Inspector to scan Lambda function code | `bool` | `true` | no |
| <a name="input_inspector_enable_lambda_scanning"></a> [inspector\_enable\_lambda\_scanning](#input\_inspector\_enable\_lambda\_scanning) | Enable Inspector to scan Lambda functions | `bool` | `true` | no |
| <a name="input_inspector_member_accounts"></a> [inspector\_member\_accounts](#input\_inspector\_member\_accounts) | List of member account IDs to enable Inspector on. The audit account cannot lookup member<br/>    accounts, so you must specify them here.<br/><br/>    This list should include all accounts in the Workloads OU and Infrastructure OU, and any other<br/>    account where you want Inspector to run. The audit account will be added automatically<br/>    whether in this list or not. | `list(string)` | `[]` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->