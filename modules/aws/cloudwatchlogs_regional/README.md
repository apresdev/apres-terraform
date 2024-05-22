# CloudWatch Logs Group

Sets up and configures regional resources for CloudWatch Logs (CWL). This is meant to be
created once per AWS account and region.

Resources created include:
* A KMS key, to be used for encrypting CloudWatch Log Groups
* An alias /aws/apres/cloudwatchlogs to be consumed by the apres/cloudwatchlogs module
* Appropriate key policy for CWL to use the key.

Future considerations:
* A subscription to move CWL to S3 or OpenSearch automatically.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

```json
{
  "Effect": "Allow",
  "Action": [
    "cloudwatch:*",
    "kms:*",
    "logs:*"
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

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to all resources | `map(string)` | <pre>{<br>  "application": "cloudwatchlogs",<br>  "component": "cloudwatchlogs",<br>  "managed-by": "terraform",<br>  "owner": "Engineering"<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for tagging AWS resources. | `string` | `"Dev"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_alias"></a> [kms\_alias](#output\_kms\_alias) | The ARN of the KMS alias used to encrypt the CloudWatch Log Group |
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | The ARN of the KMS key used to encrypt the CloudWatch Log Group |
<!-- END_TF_DOCS -->