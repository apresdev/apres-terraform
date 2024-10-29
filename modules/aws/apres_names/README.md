# Apres Names

This module provides a lightweight module used to calculate AWS Resource names, an implmentation
of the
[Naming and Tagging Standards](../../../docs/naming-and-tagging-standards.md).

The `local_name` output should be used for almost all use cases. The `global_name` output can be used for S3 buckets
and in a few other rare cases.

By default the current AWS account and region will be used, but in cases where the AWS account or region
are external, they can be set as variables and used to calculate the global resource name.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.73.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | Twelve digit AWS Account ID. If not set, the current account will be used. | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region. If not set, the current region will be used. | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_global_name"></a> [global\_name](#output\_global\_name) | The global name of the resource |
| <a name="output_local_name"></a> [local\_name](#output\_local\_name) | The local name |
<!-- END_TF_DOCS -->