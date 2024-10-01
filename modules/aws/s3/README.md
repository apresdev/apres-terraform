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
  # truncated for brevity ...
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

### Simple bucket
```hcl
module "s3" {
  source        = ""git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  environment   = "Dev"
  name          = "my-bucket"
  versioning    = true
}
```

### Set Lifecycle Rules
Delete objects after 365 days, do not transition to Intelligent Tiering
```hcl
module "s3" {
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  environment = "Dev"
  name        = "my-bucket"
  lifecycle_rule = {
    enabled                                = true
    object_delete_days                     = 365
    transition_to_intelligent_tiering_days = -1
  }
}
```

### Override the default LifeCycle Rule
```hcl
module "s3" {
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  environment = "Dev"
  name        = "my-bucket"
  lifecycle_rule = {
    enabled = false
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "default" {
  bucket = module.s3.id
  rule {
    "custom-rule-1"
    # ...
  }
  rule {
    "custom-rule-2"
    # ...
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.68.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.69.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
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
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_encryption_kms_key_id"></a> [encryption\_kms\_key\_id](#input\_encryption\_kms\_key\_id) | The ARN of the KMS key to use for server-side encryption. If not provided,<br>  the default AWS managed key 'aws/s3' will be used. | `string` | `""` | no |
| <a name="input_encryption_sse_algorithm"></a> [encryption\_sse\_algorithm](#input\_encryption\_sse\_algorithm) | The server-side encryption algorithm to use. Defaults to 'aws:kms'. | `string` | `"aws:kms"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | `"dev"` | no |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | S3 Lifecycle rules are very complex, this module supports only a subset of the rules. Since there can<br>  only be one set of Lifecycle Rules on a bucket, you have two options:<br>  1. Set the `enabled` flag to true (the default) and use the values here to configure the rules.<br>  2. Set the `enabled` flag to false and provide your own rules using the aws\_s3\_bucket\_lifecycle\_configuration<br>     resource. Do this if your requirements are more complex than what is supported here.<br><br>  Attempting to use both the default rule and your own rule will result a perpetual difference in configuration.<br><br>  Further reading:<br>  * AWS Docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html<br>  * Terraform Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration<br><br>  Note that lifecycle rules are only executed once per day. In addition S3 rounds transition or expiration dates<br>  up to midnight UTC the next day. So if you set a transition to intelligent tier to 1 day, it may take up<br>  to three days for the transition to complete. See https://repost.aws/knowledge-center/s3-lifecycle-rule-delay<br>  for a detailed explanation.<br><br>  This is a map of the following keys:<br>  * enabled - (Optional) Enable the rules, defaults to true. if you are providing your own rules set this to false<br>    and the remainder of the values will be ignored.<br>  * abort\_incomplete\_multipart\_upload\_days - (Optional) Number of days after which to abort<br>    incomplete multipart uploads. Defaults to 7. -1 means never. See the<br>    abort\_incomplete\_multipart\_upload.days\_after\_initiation field in the life cycle configuration for details.<br>  * object\_delete\_days - (Optional) Number of days after which to delete objects. Valid values are -1 to disable,<br>    or greater than 0. See the expiration.days field in the life cycle configuration for details.<br>  * old\_versions\_delete\_days - (Optional) Number of days after which to expire old versions of objects. Defaults to 30.<br>    -1 means never. See the noncurrent\_version\_expiration.days field in the life cycle configuration for details.<br>  * prefix - (Optional) The prefix to apply the lifecycle rule to. Defaults to "". An example is "logs/"<br>  * transition\_to\_intelligent\_tier\_days - (Optional) Number of days after which to transition objects<br>    to the Intelligent Tier storage class. Defaults to 1. -1 means never. | <pre>object({<br>    enabled                                = optional(bool, true)<br>    abort_incomplete_multipart_upload_days = optional(number, 7)<br>    object_delete_days                     = optional(number, -1)<br>    old_versions_delete_days               = optional(number, 30)<br>    prefix                                 = optional(string, "")<br>    transition_to_intelligent_tier_days    = optional(number, 1)<br>  })</pre> | n/a | yes |
| <a name="input_mfa_delete"></a> [mfa\_delete](#input\_mfa\_delete) | Flag to indicate if MFA delete is enabled. While this should be set to true, there is a race condition<br>  where the deploy fails to create bucket versioning if this is set to true. If you need this set to true, then<br>  you'll need to deploy it in two steps. First create the bucket with mfa\_delete=false, then set mfa\_delete=true<br>  and deploy again. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the bucket | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_set_default_bucket_policy"></a> [set\_default\_bucket\_policy](#input\_set\_default\_bucket\_policy) | A bucket policy can only be set in one place, or it'll get overwritten. For some cases you may need to add statements<br>  that include ARN's of other resources. If that's the case, set this to false, and then use the output `default_bucket_policy`<br>  to include in your own policy. For example, in your code:<pre>hcl<br>    module "s3" {<br>      # ...<br>      set_default_bucket_policy = false<br>    }<br><br>    data "aws_iam_policy_document" "default" {<br>      # your statements here<br>    }<br><br>    resource "aws_s3_bucket_policy" "default" {<br>      bucket = module.s3.bucket_name<br>      policy = data.aws_iam_policy_document.default.json<br>      source_policy_documents = [ module.s3.default_bucket_policy ]<br>    }</pre>The statement SID's must be uniuqe, the SID used in the default policy is "DenyUnSecureCommunications". | `bool` | `true` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Flag to indicate if object versioning is enabled.  Defaults to true due to best practice: Ensure AWS S3 object versioning is enabled. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The bucket domain name. Will be of format `bucketname.s3.amazonaws.com`. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The ID of the bucket, same as the name. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | The name of the S3 bucket. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | The bucket regional domain name. Will be of format `bucketname.s3.region.amazonaws.com`. |
| <a name="output_default_bucket_policy"></a> [default\_bucket\_policy](#output\_default\_bucket\_policy) | See comment on the variable `set_default_bucket_policy` for how to use this output. |
<!-- END_TF_DOCS -->
