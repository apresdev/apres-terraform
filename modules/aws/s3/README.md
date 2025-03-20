# 1. Apres S3 Terraform module

- [1. Apres S3 Terraform module](#1-apres-s3-terraform-module)
  - [1.1. Overview](#11-overview)
    - [1.1.1. Enforced Best Practices](#111-enforced-best-practices)
    - [1.1.2. Suppressed Best Practices](#112-suppressed-best-practices)
  - [1.2. Examples](#12-examples)
    - [1.2.1. Simple bucket with all the defaults](#121-simple-bucket-with-all-the-defaults)
    - [1.2.2. Set Lifecycle Rules](#122-set-lifecycle-rules)
    - [1.2.3. Override the default LifeCycle Rule](#123-override-the-default-lifecycle-rule)
    - [1.2.4. Allow pre-signed object uploads from the browser](#124-allow-pre-signed-object-uploads-from-the-browser)
  - [1.3. Replication](#13-replication)
- [2. TODO: Is this all still valid?](#2-todo-is-this-all-still-valid)
    - [2.0.1. Replication and Encryption](#201-replication-and-encryption)
    - [2.0.2. Replication Example](#202-replication-example)
    - [2.0.3. Replication and Custom Bucket Policies](#203-replication-and-custom-bucket-policies)
  - [2.1. AWS IAM Permissions](#21-aws-iam-permissions)
  - [2.2. Requirements](#22-requirements)
  - [2.3. Providers](#23-providers)
  - [2.4. Modules](#24-modules)
  - [2.5. Resources](#25-resources)
  - [2.6. Inputs](#26-inputs)
  - [2.7. Outputs](#27-outputs)


## 1.1. Overview

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

### 1.1.1. Enforced Best Practices

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

### 1.1.2. Suppressed Best Practices

The following best practices ARE NOT implemented:

| Id          | Policy                                                     |
| ----------- | ---------------------------------------------------------- |
| CKV2_AWS_62 | Ensure S3 buckets should have event notifications enabled  |
| CKV_AWS_18  | Ensure the S3 bucket has access logging enabled            |
| CKV2_AWS_61 | Ensure that an S3 bucket has a lifecycle configuration     |
| CKV_AWS_144 | Ensure that S3 bucket has cross-region replication enabled |

## 1.2. Examples

### 1.2.1. Simple bucket with all the defaults
```hcl
module "s3" {
  source       = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  name         = "my-bucket"
  environment  = "Dev"
  application  = "MyApplication"
  component    = "Storage"
  owner        = "Engineering"
}
```

### 1.2.2. Set Lifecycle Rules
Delete objects after 365 days, do not transition to Intelligent Tiering
```hcl
module "s3" {
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  name        = "my-bucket"
  environment = "Dev"
  application = "MyApplication"
  component   = "Storage"
  owner       = "Engineering"
  lifecycle_rule = {
    enabled                                = true
    object_delete_days                     = 365
    transition_to_intelligent_tiering_days = -1
  }
}
```

### 1.2.3. Override the default LifeCycle Rule
```hcl
module "s3" {
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  name        = "my-bucket"
  environment = "Dev"
  application = "MyApplication"
  component   = "Storage"
  owner       = "Engineering"
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

### 1.2.4. Allow pre-signed object uploads from the browser
```hcl
module "s3" {
  source      = "git@github.com:apresdev/apres-terraform.git//modules/aws/s3?ref=rel/s3/3.0.0"
  name        = "my-bucket"
  environment = "Dev"
  application = "MyApplication"
  component   = "Storage"
  owner       = "Engineering"
  cors_rules = [
    {
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
    }
  ]
}
```

## 1.3. Replication

This module supports replication from one bucket to another, including cross-region and cross-account.

Replication is a complex topic, see the [Setting up live replication overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-how-setup.html) for details.

The following is supported:
* Live replication from a source to destination bucket.
* Cross-region and cross-account replication
* Replication by prefix (not tags)
* Optionally, replication of delete markers

The destination bucket must exist before replication can be enabled on the source bucket. If replication is
setup across accounts, it likely cannot be accomplished in the same Terraform stack, and there are two options.

The first is to deploy in several steps:
1. Create the destination bucket without replication enabled.
2. Create the source bucket using the Bucket and KMS key ARN's used to create the destination bucket.
3. Enable replication on the destination bucket using the `source_service_role_arn` output from the source bucket module.

The second approach is to calculate the required ARN's ahead of time. You will still need to deploy the
destination bucket stack first, since replication can't be enabled on the source if the destination doesn't exist.
To use this approach, replace `${account_id}` with the 12 digit AWS Account ID in question,
and `${region}` with the region, such as `us-east-1`.

In the `replication_destination_config` set:
* source_bucket_arn: same pattern as destination_bucket_arn
* source_service_role_arn: `arn:aws:iam::${account_id}:role/${var.environment}-${var.name}-${region}-ReplicationSource`

In the `replication_source_config` set:
* destination_bucket_arn: ARN of the destination bucket, `arn:aws:s3:::${account_id}-${var.environment}-${region}-${var.name}`, ensure all is in lower case.
* destination_kms_key_arn: This cannot be an alias! Use the ARN of the KMS key, such as `arn:aws:kms:${region}:${account_id}:key/${key_id}`

Replication metrics are enabled by default, available in CloudWatch. If you wish to receive events on replication,
look at the [Amazon S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html),
which can include replication events.

### 2.0.1. Replication and Encryption

This module sets up encrypted buckets by default, using the default AWS managed key `aws/s3`. If you want
replication AND the source and destination buckets are in different AWS accounts, you must use a custom KMS key on
the destination bucket, and grant that key permissions from the AWS account where the source bucket is homed.
For example, this Key policy grants access to a remote account `111111111111` to use the key:

```json
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable Account 111111111111 to use the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::111111111111:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
```

### 2.0.2. Replication Example

In this example, we want to replicate:
* from the S3 bucket named `source-bucket` in AWS acccount 111111111111
* to the S3 bucket named `destination-bucket` in the AWS account 888888888888
* objects with the prefix `stuff-to-replicate/`
* and replicate delete markers as well (if an object is deleted in the source bucket, it will be deleted in the destination bucket)

The destination bucket:
```hcl
module "s3_destination" {
  source                   = "..."
  name                     = "destination-bucket"
  encryption_sse_algorithm = "SSE-S3"
  encrypytion_kms_key_arn  = "arn:aws:kms:us-east-1:888888888888:key/12345678-1234-1234-1234-123456789012"
  # some variables skipped for brevity
  replication_destination_config = {
    enabled                 = true
    source_bucket_account   = "111111111111"
    source_bucket_arn       = "arn:aws:s3:::source-bucket"
    source_service_role_arn = "arn:aws:iam::111111111111:role/${var.environment}-${var.name}-us-east-1-ReplicationSource"
  }
}
```

The source bucket:
```hcl
module "s3_source" {
  source = "..."
  name   = "source-bucket"
  # some variables skipped for brevity
  replication_source_config = {
    enabled                              = true
    destination_account_id               = "888888888888"
    destination_bucket_arn               = "arn:aws:s3:::destination-bucket"
    destination_encryption_sse_algorithm = "SSE-KMS"
    destination_kms_key_arn              = "arn:aws:kms:us-east-1:888888888888:key/12345678-1234-1234-1234-123456789012"
    destination_region                   = "us-east-1"
    owner_translation                    = false
    replication_prefix                   = "stuff-to-replicate/"
    replicate_delete_markers             = true
  }
}
```

### 2.0.3. Replication and Custom Bucket Policies

If you are using replication AND using a custom bucket policy by setting `set_default_bucket_policy = false`, you'll need to include the json from the output `replication_bucket_policy` in your custom bucket policy, or replication will fail.

## 2.1. AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`

```json
{
    "Effect": "Allow",
    "Action": [
        "sts:GetCallerIdentity"
    ],
    "Resource": "*"
},
{
    "Effect": "Allow",
    "Action": [
        "iam:*Role",
        "iam:*Policy",
    ],
    "Resource": [
        "arn:aws:iam::${AWS::AccountId}:role/${environment}-${name}-${AWS::Region}-ReplicationSource",
        "arn:aws:iam::${AWS::AccountId}:policy/${environment}-${name}*"
    ]
},
{
    "Effect": "Allow",
    "Action": [
        "s3:CreateBucket",
        "s3:ListBucket",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketPolicy",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketWebsite",
        "s3:GetBucketVersioning",
        "s3:GetAccelerateConfiguration",
        "s3:GetBucketRequestPayment",
        "s3:GetBucketLogging",
        "s3:GetLifecycleConfiguration",
        "s3:GetReplicationConfiguration",
        "s3:GetEncryptionConfiguration",
        "s3:GetBucketObjectLockConfiguration",
        "s3:PutBucketCORS",
        "s3:PutEncryptionConfiguration",
        "s3:PutLifecycleConfiguration",
        "s3:PutBucketVersioning",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPublicAccessBlock",
        "s3:DeleteBucketPolicy",
        "s3:DeleteBucket",
        "s3:DeleteBucketCORS"
    ],
    "Resource": "arn:aws:s3:::${AWS::AccountId}-${environment}-${AWS::Region}-${name}"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.86.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.86.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.replication_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.replication_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.replication_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.replication_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.deny_unsecure_communications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_destination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | The cors\_rule configuration block supports the following arguments:<br/><br/>  allowed\_headers - (Optional) Set of Headers that are specified in the Access-Control-Request-Headers header.<br/>  allowed\_methods - (Required) Set of HTTP methods that you allow the origin to execute. Valid values are GET, PUT, HEAD, POST, and DELETE.<br/>  allowed\_origins - (Required) Set of origins you want customers to be able to access the bucket from.<br/>  expose\_headers - (Optional) Set of headers in the response that you want customers to be able to access from their applications (for example, from a JavaScript XMLHttpRequest object). | <pre>list(object({<br/>    allowed_headers = optional(list(string), ["*"])<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    expose_headers  = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default set of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_encryption_kms_key_arn"></a> [encryption\_kms\_key\_arn](#input\_encryption\_kms\_key\_arn) | The ARN of the KMS key to use for server-side encryption. If not provided,<br/>  the default AWS managed key 'aws/s3' will be used.<br/><br/>  Note that if this bucket is the destination for replication, a KMS key must be specified. | `string` | `""` | no |
| <a name="input_encryption_sse_algorithm"></a> [encryption\_sse\_algorithm](#input\_encryption\_sse\_algorithm) | The server-side encryption algorithm to use. Defaults to 'aws:kms'. Descriptions of the options from<br/>  the AWS docs are, with the attributes passed into the API brackets:<br/>  * `SSE-S3` (AES256): Server-side encryption with Amazon S3 managed keys. This is not supported on destination<br/>     buckets in replication scenarios.<br/>  * `SSE-KMS` (aws:kms): Server-side encryption with AWS Key Management Service keys<br/>  * `DSSE-KMS` (aws:kms:dsse): Dual-layer server-side encryption with AWS KMS keys | `string` | `"SSE-KMS"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used for tagging AWS resources, and in the bucket name. | `string` | `"dev"` | no |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | S3 Lifecycle rules are very complex, this module supports only a subset of the rules. Since there can<br/>  only be one set of Lifecycle Rules on a bucket, you have three options:<br/>  1. Do not use this variable and accept the defaults.<br/>  1. Use the attributes in this variable to configure the rules.<br/>  2. Set the `enabled` attribute to false and provide your own rules using the<br/>     aws\_s3\_bucket\_lifecycle\_configuration resource. Do this if your requirements are<br/>     more complex than what is supported here.<br/><br/>  Attempting to use both the default rule and your own rule will result a perpetual difference in configuration.<br/><br/>  Further reading:<br/>  * AWS Docs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html<br/>  * Terraform Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration<br/><br/>  Note that lifecycle rules are only executed once per day. In addition S3 rounds transition or expiration dates<br/>  up to midnight UTC the next day. So if you set a transition to intelligent tier to 1 day, it may take up<br/>  to three days for the transition to complete. See https://repost.aws/knowledge-center/s3-lifecycle-rule-delay<br/>  for a detailed explanation.<br/><br/>  This is a map of the following keys:<br/>  * enabled - (Optional) Enable the rules, defaults to true. if you are providing your own rules set this to false<br/>    and the remainder of the values will be ignored.<br/>  * abort\_incomplete\_multipart\_upload\_days - (Optional) Number of days after which to abort<br/>    incomplete multipart uploads. Defaults to 7. -1 means never. See the<br/>    abort\_incomplete\_multipart\_upload.days\_after\_initiation field in the life cycle configuration for details.<br/>  * object\_delete\_days - (Optional) Number of days after which to delete objects. Valid values are -1 to disable,<br/>    or greater than 0. See the expiration.days field in the life cycle configuration for details.<br/>  * old\_versions\_delete\_days - (Optional) Number of days after which to expire old versions of objects. Defaults to 30.<br/>    -1 means never. See the noncurrent\_version\_expiration.days field in the life cycle configuration for details.<br/>  * prefix - (Optional) The prefix to apply the lifecycle rule to. Defaults to "". An example is "logs/"<br/>  * transition\_to\_intelligent\_tier\_days - (Optional) Number of days after which to transition objects<br/>    to the Intelligent Tier storage class. Defaults to 1. -1 means never. | <pre>object({<br/>    enabled                                = optional(bool, true)<br/>    abort_incomplete_multipart_upload_days = optional(number, 7)<br/>    object_delete_days                     = optional(number, -1)<br/>    old_versions_delete_days               = optional(number, 30)<br/>    prefix                                 = optional(string, "")<br/>    transition_to_intelligent_tier_days    = optional(number, 1)<br/>  })</pre> | n/a | yes |
| <a name="input_mfa_delete"></a> [mfa\_delete](#input\_mfa\_delete) | Flag to indicate if MFA delete is enabled. While this should be set to true, there is a race condition<br/>  where the deploy fails to create bucket versioning if this is set to true. If you need this set to true, then<br/>  you'll need to deploy it in two steps. First create the bucket with mfa\_delete=false, then set mfa\_delete=true<br/>  and deploy again. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the bucket | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_replication_destination_config"></a> [replication\_destination\_config](#input\_replication\_destination\_config) | Object to configure the bucket as the destination of replication. All attributes are ignored if `enabled` is false.<br/><br/>  Attributes:<br/>  * enabled - set to true if this is the destination bucket, else replication will not be enabled.<br/>  * source\_bucket\_account - The AWS Account ID where the source bucket is homed.<br/>  * source\_bucket\_arn - The ARN of the source bucket.<br/>  * source\_service\_role\_arn - The ARN of the service role that will be used to replicate objects. Note that<br/>    depending on how the role was created, it could be two different patterns:<br/>    * arn:aws:iam::account-id:role/role-name - created with the CLI or via this module<br/>    * arn:aws:iam::account-id:role/service-role/role-name - created with the Console<br/>    See the output `replication_source_iam_role` for the IAM role created by this module on the source bucket. | <pre>object({<br/>    enabled                 = bool<br/>    source_bucket_account   = string<br/>    source_bucket_arn       = string<br/>    source_service_role_arn = string<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "source_bucket_account": "",<br/>  "source_bucket_arn": "",<br/>  "source_service_role_arn": ""<br/>}</pre> | no |
| <a name="input_replication_source_config"></a> [replication\_source\_config](#input\_replication\_source\_config) | Object to configure the bucket as the source of replication. All attributes are ignored if `enabled` is false.<br/>  Attributes:<br/>  * enabled - set to true if this is the source bucket, else replication will not be enabled.<br/>  * destination\_account\_id - The AWS Account ID where the destination bucket is homed.<br/>  * destination\_bucket\_arn - The ARN of the destination bucket.<br/>  * destination\_encryption\_sse\_algorithm - The encryption algorithm to use for encryption on the destination bucket.<br/>    This must match what the destination bucket is configured for. Options are "SSE-S3", "SSE-KMS", or "DSSE-KMS". See<br/>    the variable `encryption_sse_algorithm` for more information. Note that "SSE-S3" is not supported for cross-account<br/>    replication.<br/>  * destination\_kms\_key\_arn - The ARN of the KMS key to use for server-side encryption in the destination bucket. This<br/>    can be the Key or Alias ARN. If the encryption on the destination bucket is "SSE-KMS", and the destination bucket<br/>    is in a different AWS account, aliases cannot be used, or the replication will fail. You MUST<br/>    specify the KMS Key ARN, NOT an alias.<br/>  * destination\_region - The region of the destination bucket.<br/>  * owner\_translation - If true, ownership (AWS Account ID) of the object in the destination bucket will be set to the owner<br/>    of the destination bucket. If false, the owner of the object written in the destination bucket will be that<br/>    of the source bucket.<br/>  * replication\_prefix - The prefix to apply to the replication configuration, default is everything. Include wildcards<br/>    if necessary. For example "Tax/" or "Tax*" are both legitimate.<br/>  * replicate\_delete\_markers - Flag to indicate if delete markers should be replicated, which means objects<br/>    deleted in the source bucket will also be deleted in the destination bucket. | <pre>object({<br/>    enabled                              = bool<br/>    destination_account_id               = string<br/>    destination_bucket_arn               = string<br/>    destination_encryption_sse_algorithm = string<br/>    destination_kms_key_arn              = string<br/>    destination_region                   = string<br/>    owner_translation                    = bool<br/>    replicate_delete_markers             = bool<br/>    replication_prefix                   = string<br/>  })</pre> | <pre>{<br/>  "destination_account_id": "",<br/>  "destination_bucket_arn": "",<br/>  "destination_encryption_sse_algorithm": "",<br/>  "destination_kms_key_arn": "",<br/>  "destination_region": "",<br/>  "enabled": false,<br/>  "owner_translation": true,<br/>  "replicate_delete_markers": false,<br/>  "replication_prefix": ""<br/>}</pre> | no |
| <a name="input_set_default_bucket_policy"></a> [set\_default\_bucket\_policy](#input\_set\_default\_bucket\_policy) | A bucket policy can only be set in one place, or it'll get overwritten. For some cases you may need to add statements<br/>  that include ARN's of other resources. If that's the case, set this to false, and then use the output<br/>  `default_bucket_policy` to include in your own policy.<br/><br/>  If replication is desired and this is set to false, you must include the `replication_bucket_policy` output in your<br/>  bucket policy as well, else replication will not succeed!<br/><br/>  For example, in your code:<pre>hcl<br/>    module "s3" {<br/>      # ...<br/>      set_default_bucket_policy = false<br/>    }<br/><br/>    data "aws_iam_policy_document" "default" {<br/>      # your statements here<br/>    }<br/><br/>    resource "aws_s3_bucket_policy" "default" {<br/>      bucket = module.s3.bucket_name<br/>      policy = data.aws_iam_policy_document.default.json<br/>      source_policy_documents = [ module.s3.default_bucket_policy ]<br/>    }</pre>The statement SID's must be unique, the SID used in the default policy is "DenyUnSecureCommunications". | `bool` | `true` | no |
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
| <a name="output_replication_bucket_policy"></a> [replication\_bucket\_policy](#output\_replication\_bucket\_policy) | The bucket policy json for the replication destination bucket. This is only created if replication is enabled and<br/>    `set_default_bucket_policy` is false, in which case it is the calling stack's responsibility to add this<br/>    policy document to the bucket policy, else replication will not work. |
| <a name="output_replication_source_service_role_arn"></a> [replication\_source\_service\_role\_arn](#output\_replication\_source\_service\_role\_arn) | The IAM role name for the replication source.  This is only created if replication is enabled and this<br/>    is the source bucket. This Role ARN is needed to allow the destination bucket to replicate from this bucket. |
<!-- END_TF_DOCS -->
