# Apres DynamoDb Terraform module

## Overview

This module will create a DynamoDb table in accordance with best practices. DynamoDB tables names do not need to be globally unique in AWS, and table names will be created using the following patterN:

`environment`-`name`

where:

* `environment` is the lower case `environment` variable passed into the terraform stack
* `name` is the lower case `name` variable passed into the terraform stack.

For example, if the stack is deployed with:

```hcl
module "dynamodb" {
  source      = "TBD" # value depends on your installation
  name        = "mytesttable"
  environment = "SystemTest"
  hash_key    = "pk"
  attributes  = [
    {
      name = "pk"
      type = "S"
    }
  ]
}
```

the table name will be `SystemTest-mytesttable`

### Enforced Best Practices

The following best practices are applied to the table:

| Id          | Policy                                                                |
|-------------|-----------------------------------------------------------------------|
| CKV_AWS_28  | Ensure DynamoDB point in time recovery (backup) is enabled            |
| CKV_AWS_119 | Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK |
| CKV2_AWS_16 | Ensure that Auto Scaling is enabled on your DynamoDB tables           |

### Suppressed Best Practices

The following best practices ARE NOT implemented:

| Id | Policy |
|----|--------|

## Example

```hcl
module "dynamodb" {
  source      = "../../../modules/dynamodb"
  environment = "Dev"
  name        = "my-table"
  hash_key    = "pk"
  attributes  = [
    {
      name = "pk"
      type = "S"
    }
  ]
}
```

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`
- `${encryption_kms_key_id}` with the lower case of the variable `var.encryption_kms_key_id` (if specified)

```json
{
    "Effect": "Allow",
    "Action": [
        "sts:GetCallerIdentity",
        "application-autoscaling:DescribeScalableTargets",
        "application-autoscaling:DescribeScalingPolicies",
        "application-autoscaling:ListTagsForResource"
    ],
    "Resource": "*"
},
{
    "Effect": "Allow",
    "Action": [
        "dynamodb:*"
    ],
    "Resource": "arn:aws:dynamodb:${AWS::Region}:${AWS::AccountId}:table/${environment}-${name}"
},
{
    "Effect": "Allow",
    "Action": [
        "kms:DescribeKey"
    ],
    "Resource": [
      "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/dynamodb",
      "${encryption_kms_key_id}"
    ]
},
{
    "Effect": "Allow",
    "Action": [
        "application-autoscaling:*"
    ],
    "Resource": "arn:aws:application-autoscaling:${AWS::Region}:${AWS::AccountId}:scalable-target/table/${AWS::AccountId}-${environment}-${AWS::Region}-${name}"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.table_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.table_write_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.table_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_appautoscaling_target.table_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_dynamodb_table.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | List of nested attribute definitions. Only required for hash\_key and range\_key attributes.<br/>  Each attribute has two properties:<br/>    name - (Required) The name of the attribute,<br/>    type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data | `list(map(string))` | `[]` | no |
| <a name="input_autoscaling_defaults"></a> [autoscaling\_defaults](#input\_autoscaling\_defaults) | A map of default autoscaling settings | `map(string)` | <pre>{<br/>  "scale_in_cooldown": 0,<br/>  "scale_out_cooldown": 0,<br/>  "target_value": 70<br/>}</pre> | no |
| <a name="input_autoscaling_enabled"></a> [autoscaling\_enabled](#input\_autoscaling\_enabled) | Flag indicating whether or not to enable autoscaling. Default is true | `bool` | `true` | no |
| <a name="input_autoscaling_indexes"></a> [autoscaling\_indexes](#input\_autoscaling\_indexes) | A map of index autoscaling configurations. | `map(map(string))` | `{}` | no |
| <a name="input_autoscaling_read"></a> [autoscaling\_read](#input\_autoscaling\_read) | A map of read autoscaling settings. `max_capacity` is the only required key.  Default is 1,000. | `map(string)` | <pre>{<br/>  "max_capacity": 1000<br/>}</pre> | no |
| <a name="input_autoscaling_write"></a> [autoscaling\_write](#input\_autoscaling\_write) | A map of write autoscaling settings. `max_capacity` is the only required key.  Default is 1,000. | `map(string)` | <pre>{<br/>  "max_capacity": 1000<br/>}</pre> | no |
| <a name="input_billing_mode"></a> [billing\_mode](#input\_billing\_mode) | (Optional) Controls how you are charged for read and write throughput and how you manage capacity. The valid values are PROVISIONED and<br/>  PAY\_PER\_REQUEST. Defaults to PROVISIONED. | `string` | `"PROVISIONED"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | (Optional) Enables deletion protection for table. Defaults to true. | `bool` | `true` | no |
| <a name="input_encryption_kms_key_id"></a> [encryption\_kms\_key\_id](#input\_encryption\_kms\_key\_id) | The ARN of the KMS key to use for server-side encryption. If not provided,<br/>  the default AWS managed key 'aws/dynamodb' will be used. | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | n/a | yes |
| <a name="input_global_secondary_indices"></a> [global\_secondary\_indices](#input\_global\_secondary\_indices) | List of definitions for global secondary indices. Note that any Dynamo attributes must<br/>  be defined in the attributes variable.<br/>  Each "global\_secondary\_indices" variable has the following properties:<br/>    name - (Required) The name of the global secondary index.<br/>    hash\_key - (Required) The attribute to use as the hash (partition) key. Must also be<br/>      defined as an attribute<br/>    range\_key - (Optional) The attribute to use as the range (sort) key. Must also be<br/>      defined as an attribute<br/>    write\_capacity - (Optional) The number of write units for this index. Do not specify<br/>      if using an on-demand (PAY\_PER\_REQUEST) table.<br/>    read\_capacity - (Optional) The number of read units for this index. Do not specify<br/>      if using an on-demand table.<br/>    projection\_type - (Optional) One of ALL, KEYS\_ONLY, INCLUDE. Default is ALL.<br/>    non\_key\_attributes - (Optional) List of attributes that are copied from the table<br/>      into the index. These attributes are in addition to the primary key attributes and<br/>      index key attributes, and are projected into the index. | <pre>list(object({<br/>    name               = string<br/>    hash_key           = string<br/>    range_key          = optional(string, "")<br/>    write_capacity     = optional(number, null)<br/>    read_capacity      = optional(number, null)<br/>    projection_type    = optional(string, "ALL")<br/>    non_key_attributes = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_hash_key"></a> [hash\_key](#input\_hash\_key) | The attribute to use as the hash (partition) key. Must also be defined as an attribute | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the table, must be between 3 and 255 characters long and can contain only the following characters: a-z, A-Z, 0-9, \_, -, and . | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_point_in_time_recovery_enabled"></a> [point\_in\_time\_recovery\_enabled](#input\_point\_in\_time\_recovery\_enabled) | (Optional) Whether to enable Point In Time Recovery for the replica. Default is true. | `bool` | `true` | no |
| <a name="input_range_key"></a> [range\_key](#input\_range\_key) | (Optional) The attribute to use as the range (sort) key. Must also be defined as an attribute | `string` | `null` | no |
| <a name="input_read_capacity"></a> [read\_capacity](#input\_read\_capacity) | The number of read units for this table.<br/>  If the billing\_mode is PROVISIONED, then read\_capacity should be greater than 0. | `number` | `5` | no |
| <a name="input_stream_enabled"></a> [stream\_enabled](#input\_stream\_enabled) | Indicates whether Streams are to be enabled (true) or disabled (false). | `bool` | `false` | no |
| <a name="input_stream_view_type"></a> [stream\_view\_type](#input\_stream\_view\_type) | When an item in the table is modified, StreamViewType determines what information is written to the table's stream. | `string` | `null` | no |
| <a name="input_table_class"></a> [table\_class](#input\_table\_class) | (Optional) Storage class of the table. Valid values are STANDARD and STANDARD\_INFREQUENT\_ACCESS. Default value is STANDARD | `string` | `"STANDARD"` | no |
| <a name="input_ttl_attribute_name"></a> [ttl\_attribute\_name](#input\_ttl\_attribute\_name) | (Optional) Name of the table attribute to store the TTL timestamp in. Required if ttl\_enabled is true, must not be set otherwise. | `string` | `""` | no |
| <a name="input_ttl_enabled"></a> [ttl\_enabled](#input\_ttl\_enabled) | Indicates whether ttl is enabled | `bool` | `false` | no |
| <a name="input_write_capacity"></a> [write\_capacity](#input\_write\_capacity) | The number of write units for this table.<br/>  If the billing\_mode is PROVISIONED, then write\_capacity should be greater than 0. | `number` | `5` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_stream_arn"></a> [stream\_arn](#output\_stream\_arn) | ARN of the Table Stream. Only available when stream\_enabled = true. |
| <a name="output_table_arn"></a> [table\_arn](#output\_table\_arn) | The ARN of the DynamoDB table. |
| <a name="output_table_name"></a> [table\_name](#output\_table\_name) | The name of the DynamoDB table. |
<!-- END_TF_DOCS -->
