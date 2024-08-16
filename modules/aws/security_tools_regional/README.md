# Apres AWS Region-specific Security Tools configuration

This module configures the region-specific security tools. Services such as GuardDuty are deployed
per-region (and in future Inspector and Detective) and thus require a pre-region deployment.

This module sets up:
* Amazon GuardDuty, publishing to Security Hub (configured in the _security\_tools_ module)

## Considerations with AWS Organizations

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

## Future enhancements
1. Add other region-specific services like Inspector, Detective, etc will be added in future versions.
2. Export GuardDuty events to S3. See [Export findings](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_exportfindings.html)

## Prerequisites

### Delegate Management

Run the [security_tools_delegator](../security_tools_delegator/README.md) module against the management account of your organization. This sets
up the delegation for the services that this module configures. This module will fail to deploy without that.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed.

```json
{
  "Action": [
     "guardduty:*"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.62.0 |

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
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->