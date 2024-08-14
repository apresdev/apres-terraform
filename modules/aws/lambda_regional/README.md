# Lambda Regional Module

Sets up and configures regional resources for Lambda Functions. This is meant to be deployed once per AWS account and region.

Resources created include:

* An S3 bucket used to deploy lambda-artifacts
* A code signing profile for lambda
* A code signing configuration that requires the code signing profile
* An SSM parameter with the ARN of the code signing configuration

# A note on Code Signing Profiles

Code Signing Profiles are somewhat bespoke AWS resources. They can never be deleted and can never be renamed. Hence, the use of `name_prefix` rather
than `name` in the terraform code. This ensures that each terraform deployment generates its own unique resource name.

Moreover, code signing profiles are revocable; however, this is a one-way operation, in that once revoked, a code signing profile can never be
un-revoked. Therefore, great care should be taken with these resources as they can be put in an unrecoverable state (i.e. it's best to just leave them
alone, especially in the AWS console).

Fortunately, code signing profiles are *free*, as such, dangling or zombied signing profiles are mostly a nuisance.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`

```json
[
  {
    "Effect": "Allow",
    "Action": [
      "signer:PutSigningProfile",
      "lambda:CreateCodeSigningConfig",
      "ssm:DescribeParameters"
    ],
    "Resource": "*"
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
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:DeleteBucketPolicy",
      "s3:DeleteBucket"
    ],
    "Resource": "arn:aws:s3:::${AWS::AccountId}-${environment}-${AWS::Region}-lambda-artifacts"
  },
  {
    "Effect": "Allow",
    "Action": [
      "signer:GetSigningProfile",
      "signer:CancelSigningProfile"
    ],
    "Resource": "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-profiles/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:GetCodeSigningConfig",
      "lambda:DeleteCodeSigningConfig"
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:code-signing-config:*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:GetParameter"
    ],
    "Resource": "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter/apres/lambda/lambda-signing-config-arn"
  }
]
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                      | Version           |
|---------------------------------------------------------------------------|-------------------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 5.0.0          |

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.41.0  |

## Modules

| Name                                                                       | Source                                                      | Version      |
|----------------------------------------------------------------------------|-------------------------------------------------------------|--------------|
| <a name="module_s3_artifacts"></a> [s3\_artifacts](#module\_s3\_artifacts) | git@github.com:apresdev/apres-terraform.git//modules/aws/s3 | rel/s3/2.0.1 |

## Resources

| Name                                                                                                                                             | Type     |
|--------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [aws_lambda_code_signing_config.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_code_signing_config) | resource |
| [aws_signer_signing_profile.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/signer_signing_profile)         | resource |

## Inputs

| Name                                                                | Description                                                  | Type          | Default            | Required |
|---------------------------------------------------------------------|--------------------------------------------------------------|---------------|--------------------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources.            | `string`      | `"CloudWatchLogs"` |    no    |
| <a name="input_component"></a> [component](#input\_component)       | Component name, used for tagging AWS resources.              | `string`      | `"CloudWatchLogs"` |    no    |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string`      | n/a                |   yes    |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags)  | Extra tags to be applied to all resources                    | `map(string)` | `{}`               |    no    |
| <a name="input_owner"></a> [owner](#input\_owner)                   | Owner of the resources, used for tagging AWS resources.      | `string`      | `"Engineering"`    |    no    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
