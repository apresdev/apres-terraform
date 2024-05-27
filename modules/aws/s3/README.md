# Apres S3 Terraform module

## Overview

This module will create an S3 bucket in accordance with best practices. Since bucket names must be globally unique in AWS,
the resulting name will have the following pattern:

  <account-id>-<environment>-<region>-<name>

where:
* `account-id` is the 12 digit AWS account where the bucket is deployed.
* `environment` is the lower case `environment` variable passed into the terraform stack
* `region` is the AWS region where the bucket is deployed
* `name` is the lower case `name` variable passed into the terraform stack.

For example, if the stack is deployed with:

```hcl
module "s3" {
  source = "TBD" # value depends on your installation
  name = "mytestbucket"
  environment = "SystemTest"
}
```

and the stack is deployed to the AWS account 12345689012 in us-east-2, the bucket name will be `123456789012-systemtest-us-east-2-mytestbucket`

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

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.deny_unsecure_communications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.deny_unsecure_communications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_encryption_kms_key_id"></a> [encryption\_kms\_key\_id](#input\_encryption\_kms\_key\_id) | The ARN of the KMS key to use for server-side encryption. If not provided,<br>  the default AWS managed key 'aws/s3' will be used. | `string` | `""` | no |
| <a name="input_encryption_sse_algorithm"></a> [encryption\_sse\_algorithm](#input\_encryption\_sse\_algorithm) | The server-side encryption algorithm to use. Defaults to 'aws:kms'. | `string` | `"aws:kms"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | `"dev"` | no |
| <a name="input_mfa_delete"></a> [mfa\_delete](#input\_mfa\_delete) | Flag to indicate if MFA delete is enabled. While this should be set to true, there is a race condition<br>  where the deploy fails to create bucket versioning if this is set to true. If you need this set to true, then<br>  you'll need to deploy it in two steps. First create the bucket with mfa\_delete=false, then set mfa\_delete=true<br>  and deploy again. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the bucket | `string` | n/a | yes |
| <a name="input_set_default_bucket_policy"></a> [set\_default\_bucket\_policy](#input\_set\_default\_bucket\_policy) | A bucket policy can only be set in one place, or it'll get overwritten. For some cases you may need to add statements<br>  that include ARN's of other resources. If that's the case, set this to false, and then use the output `default_bucket_policy`<br>  to include in your own policy. For example, in your code:<pre>hcl<br>    module "s3" {<br>      # ...<br>      set_default_bucket_policy = false<br>    }<br><br>    data "aws_iam_policy_document" "default" {<br>      # your statements here<br>    }<br><br>    resource "aws_s3_bucket_policy" "default" {<br>      bucket = module.s3.bucket_name<br>      policy = data.aws_iam_policy_document.default.json<br>      source_policy_documents = [ module.s3.default_bucket_policy ]<br>    }</pre>The statement SID's must be uniuqe, the SID used in the default policy is "DenyUnSecureCommunications". | `bool` | `true` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Flag to indicate if object versioning is enabled.  Defaults to true due to best practice: Ensure AWS S3 object versioning is enabled. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The bucket domain name. Will be of format `bucketname.s3.amazonaws.com`. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | The name of the S3 bucket. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | The bucket regional domain name. Will be of format `bucketname.s3.region.amazonaws.com`. |
| <a name="output_default_bucket_policy"></a> [default\_bucket\_policy](#output\_default\_bucket\_policy) | See comment on the variable `set_default_bucket_policy` for how to use this output. |
<!-- END_TF_DOCS -->
