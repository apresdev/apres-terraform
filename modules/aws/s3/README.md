# Apres S3 Terraform module

## Overview

This module will create an S3 bucket in accordance with best practices.

### Enforced Best Practices

The following best practices are applied to the bucket:

| Id          | Policy                                                                                                    |
| ----------- | --------------------------------------------------------------------------------------------------------- |
| CKV_AWS_93  | Ensure S3 bucket policy does not lockout all but root user. (Prevent lockouts needing root account fixes) |
| CKV_AWS_53  | Ensure S3 bucket has block public ACLS enabled                                                            |
| CKV_AWS_55  | Ensure S3 bucket has ignore public ACLs enabled                                                           |
| CKV_AWS_56  | Ensure S3 bucket has 'restrict_public_buckets' enabled                                                    |
| CKV_AWS_54  | Ensure S3 bucket has block public policy enabled                                                          |
| CKV_AWS_93  | Ensure S3 bucket policy does not lockout all but root user. (Prevent lockouts needing root account fixes) |
| CKV2_AWS_43 | Ensure S3 Bucket does not allow access to all Authenticated users                                         |
| CKV_AWS_21  | Ensure all data stored in the S3 bucket have versioning enabled                                           |
| CKV_AWS_57  | S3 Bucket has an ACL defined which allows public WRITE access.                                            |
| CKV2_AWS_6  | Ensure that S3 bucket has a Public Access block                                                           |
| CKV_AWS_20  | S3 Bucket has an ACL defined which allows public READ access.                                             |
| CKV_AWS_145 | Ensure that S3 buckets are encrypted with KMS by default                                                  |
| CKV_AWS_19  | Ensure all data stored in the S3 bucket is securely encrypted at rest                                     |

### Suppressed Best Practices

The following best practices ARE NOT implemented:

| Id          | Policy                                                     |
| ----------- | ---------------------------------------------------------- |
| CKV2_AWS_62 | Ensure S3 buckets should have event notifications enabled  |
| CKV_AWS_18  | Ensure the S3 bucket has access logging enabled            |
| CKV2_AWS_61 | Ensure that an S3 bucket has a lifecycle configuration     |
| CKV_AWS_144 | Ensure that S3 bucket has cross-region replication enabled |

## Example

```hcl
module "s3" {
  source        = "../../../modules/s3"
  environment   = "Dev"
  name          = "my-bucket"
  versioning    = true
  mfa_delete    = true
}
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | ~> 1.6   |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                                                                     | Type        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_s3_bucket.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                                           | resource    |
| [aws_s3_bucket_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl)                                                                   | resource    |
| [aws_s3_bucket_policy.deny_unsecure_communications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)                                        | resource    |
| [aws_s3_bucket_public_access_block.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)                                   | resource    |
| [aws_s3_bucket_server_side_encryption_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource    |
| [aws_s3_bucket_versioning.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)                                                     | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                                            | data source |
| [aws_iam_policy_document.deny_unsecure_communications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                               | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                                              | data source |

## Inputs

| Name                                                               | Description                                                                                                                          | Type     | Default | Required |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ | -------- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input_environment) | Environment name, used for tagging AWS resources.                                                                                    | `string` | `"dev"` |    no    |
| <a name="input_mfa_delete"></a> [mfa_delete](#input_mfa_delete)    | Flag to indicate if MFA delete is enabled. Defaults to true due to best practice: Ensure S3 bucket MFA Delete is enabled.            | `bool`   | `true`  |    no    |
| <a name="input_name"></a> [name](#input_name)                      | Name of the bucket                                                                                                                   | `string` | n/a     |   yes    |
| <a name="input_versioning"></a> [versioning](#input_versioning)    | Flag to indicate if object versioning is enabled. Defaults to true due to best practice: Ensure AWS S3 object versioning is enabled. | `bool`   | `true`  |    no    |

## Outputs

| Name                                                                                      | Description                                                              |
| ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| <a name="output_bucket_arn"></a> [bucket_arn](#output_bucket_arn)                         | The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`.      |
| <a name="output_bucket_domain_name"></a> [bucket_domain_name](#output_bucket_domain_name) | The bucket domain name. Will be of format `bucketname.s3.amazonaws.com`. |
| <a name="output_bucket_name"></a> [bucket_name](#output_bucket_name)                      | The name of the S3 bucket.                                               |

<!-- END_TF_DOCS -->
