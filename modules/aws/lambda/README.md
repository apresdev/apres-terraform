# Lambda Function

This module will create a Lambda function queue in accordance with best practices. Lambda function names do not need to be globally unique in AWS; as
such, the resulting name will have the following pattern:

`environment`-`name`

Resources created include:

* If `source_file` is set, a zip file archiving the specified file.
* An S3 object containing the unsigned archive file, generated (see previous bullet) or specified in `zip_file`
* A signing job the signs the archive with the `lamda_regional` code signing profile
* A CloudWatch Log Group (CWL) for the function (`/apres/lambda/<function_name>`)
* A Dead-letter SQS queue (DLQ) for any failed invocations of the lambda function.
* An IAM execution role for the lambda function (outputs the role ARN via `iam_role_arn`)
* A default IAM policy attached to the role that grants access to the CWL, the DLQ, and permissions to the VPC if `vpc.enabled` is `true`
* A lambda function using the above resources
* (Optional) - A Security Group for the function if `vpc.enabled` is `true`

## Custom IAM permissions

The module creates a default IAM role and a default policy that grants the lambda permission to access all resources managed within the module.

Module users will likely need to grant additional permissions to resources needed by their lambda functions (e.g. the `dynamodb_sns_publisher`
needs permissions to publish to a SNS topic ). To accommodate this the module exposes the ARN and the name of the IAM execution role for the lambda
via `iam_role_arn` and `iam_role_name` respectively.

Module users can then simply attach roles using the standard AWS terraform resources. For example:

```hcl
module "lambda" {
  # Include lambda input variables...
}

# This grants the permissions the lambda needs during execution
data "aws_iam_policy_document" "default" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.topic_arn]
  }
}

# Attaches the additional lambda permissions to the policy
resource "aws_iam_role_policy" "default" {
  role   = module.lambda.iam_role_name
  policy = data.aws_iam_policy_document.default.json
}
```

# Lambda and Networking in VPC

Lambda supports VPC access, this module does so with the `vpc` variable. The doc
[Giving Lambda functions access to resources in an Amazon VPC](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html) has details on it works.

Typically it takes about five minutes to delete the ENI's and associated security groups, but occasionally
it can take up to 60 minutes. This is a known AWS limitation, and there is little that can be done about it.

The details of how the networking configuration works:
* When a Lambda function is configured with VPC access, the Lambda service creates ENI's are created in each
  specified subnet, and the security group created by this module is attached to the ENI's. When the Lambda
  function executes, it uses the ENI's to access the VPC.
* When the Lambda function is deleted, the ENI's are not automatically deleted. They are marked for deletion, and AWS
  has an opaque background process that cleans up the ENI's. There is no visibility into the process, and no
  way to speed it up.
* While waiting for the deletion, the ENI is marked as type `lambda`, with status `In-use`. Because it's still
  in use, it cannot be modified. Further, if a custom security group is attached, that security group cannot
  be deleted until the cleanup process is completed.
* The Terraform provider for AWS has a `replace_security_group_on_destroy` flag which in theory can speed up deletion.
  When that flag is set and the Lambda function is deleted, the provider first modifies the security group on the
  Lambda function to be the default security group, and then deletes the function. The problem is that instead of
  updating the security group attached to the ENI's in place, the Lambda service creates new ENI's with the default
  security group attached, leaving the pre-existing ENI's with the old security group still attached. Worse, the
  new ENI's are never marked for deletion, and will remain in your AWS account until you manually delete them.

# Lambda@Edge

Lambda@Edge has some restrictions, which are enabled by setting the `is_lambda_at_edge` variable to true. The
following changes are enforced:
* the Lambda will be deployed in us-east-1, regardless of what `region` is set to.
* the service principal `edgelambda.amazonaws.com` will be added to the IAM execution role.
* VPC connectivity will be ignored.
* Dead letter queues will not be created.
* Environment variables will not be set, and additions passed in via the `environment_variables`
  variable will be ignored.
* ARM64 architecture is not supported, `architectures` must be set to `x86_64`. The developer
  must ensure any binaries are compiled to the correct architecture, there is no preflight
  check for this.

See [Restrictions on Lambda@Edge](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-at-edge-function-restrictions.html) for more details.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.

- `${AWS::AccountId}` with the Account ID where this stack is deployed.
- `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
- `${environment}` with the lower case of the variable `var.environment`
- `${name}` with the lower case of the variable `var.name`
- `${lambda_regional_environment}` with the lower case of the variable `var.lambda_regional_environment`

```json
[
  {
    "Effect": "Allow",
    "Action": [
      "sts:GetCallerIdentity",
      "kms:ListAliases",
      "logs:DescribeLogGroups"
    ],
    "Resource": "*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "ssm:GetParameter"
    ],
    "Resource": [
      "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter//apres/lambda/signing-config-arn",
      "arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter//apres/lambda/signing-profile-name"
    ]
  },
  {
    "Effect": "Allow",
    "Action": [
      "signer:GetSigningProfile",
      "signer:StartSigningJob"
    ],
    "Resource": "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-profiles/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "s3:ListBucket",
      "s3:GetBucketWebsite",
      "s3:ListBucketVersions"
    ],
    "Resource": "arn:aws:s3:::${AWS::AccountId}-${lambda_regional_environment}-${AWS::Region}-lambda-artifacts"
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:GetCodeSigningConfig"
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:code-signing-config:*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:DescribeKey"
    ],
    "Resource": [
      "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/lambda",
      "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/s3"
    ]
  },
  {
    "Effect": "Allow",
    "Action": [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:PassRole",
      "iam:DeleteRolePolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:DeleteRole"
    ],
    "Resource": "arn:aws:iam::${AWS::AccountId}:role/${environment}-${name}-*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
      "logs:ListTagsForResource",
      "logs:DeleteLogGroup"
    ],
    "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/apres/lambda/${environment}-${name}"
  },
  {
    "Effect": "Allow",
    "Action": [
      "sqs:CreateQueue",
      "sqs:TagQueue",
      "sqs:GetQueueAttributes",
      "sqs:ListQueueTags",
      "sqs:DeleteQueue"
    ],
    "Resource": "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${environment}-${name}-deadletter"
  },
  {
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:DeleteObject"
    ],
    "Resource": "arn:aws:s3:::${AWS::AccountId}-${lambda_regional_environment}-${AWS::Region}-lambda-artifacts/unsigned/${environment}-${name}.zip"
  },
  {
    "Effect": "Allow",
    "Action": [
      "signer:DescribeSigningJob"
    ],
    "Resource": "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-jobs/*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:CreateFunction",
      "lambda:GetFunction",
      "lambda:ListVersionsByFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:DeleteFunction"
    ],
    "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:${environment}-${name}"
  }
]

```

### Enforced Best Practices

The following best practices are applied:

| Id          | Policy                                                                                              |
|-------------|-----------------------------------------------------------------------------------------------------|
| CKV_AWS_66  | Ensure that CloudWatch Log Group specifies retention days                                           |
| CKV_AWS_27  | Ensure all data stored in the SQS queue is encrypted                                                |
| CKV_AWS_168 | Ensure SQS queue policy is not public by only allowing specific services or principals to access it |
| CKV_AWS_25  | Ensure no security groups allow ingress from 0.0.0.0:0 to port 3389                                 |
| CKV_AWS_23  | Ensure every security group and rule has a description                                              |
| CKV_AWS_277 | Ensure no security groups allow ingress from 0.0.0.0:0 to port -1                                   |
| CKV_AWS_24  | Ensure no security groups allow ingress from 0.0.0.0:0 to port 22                                   |
| CKV_AWS_260 | Ensure no security groups allow ingress from 0.0.0.0:0 to port 80                                   |
| CKV_AWS_356 | Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions       |
| CKV_AWS_358 | Ensure GitHub Actions OIDC trust policies only allows actions from a specific known organization    |
| CKV_AWS_110 | Ensure IAM policies does not allow privilege escalation                                             |
| CKV_AWS_49  | Ensure no IAM policies documents allow "*" as a statement's actions                                 |
| CKV_AWS_107 | Ensure IAM policies does not allow credentials exposure                                             |
| CKV_AWS_283 | Ensure no IAM policies documents allow ALL or any AWS principal permissions to the resource         |
| CKV_AWS_109 | Ensure IAM policies does not allow permissions management / resource exposure without constraints   |
| CKV_AWS_1   | Ensure IAM policies that allow full "*-*" administrative privileges are not created                 |
| CKV_AWS_108 | Ensure IAM policies does not allow data exfiltration                                                |
| CKV_AWS_111 | Ensure IAM policies does not allow write access without constraints                                 |
| CKV_AWS_356 | Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions       |
| CKV_AWS_358 | Ensure GitHub Actions OIDC trust policies only allows actions from a specific known organization    |
| CKV_AWS_110 | Ensure IAM policies does not allow privilege escalation                                             |
| CKV_AWS_49  | Ensure no IAM policies documents allow "*" as a statement's actions                                 |
| CKV_AWS_107 | Ensure IAM policies does not allow credentials exposure                                             |
| CKV_AWS_283 | Ensure no IAM policies documents allow ALL or any AWS principal permissions to the resource         |
| CKV_AWS_109 | Ensure IAM policies does not allow permissions management / resource exposure without constraints   |
| CKV_AWS_1   | Ensure IAM policies that allow full "*-*" administrative privileges are not created                 |
| CKV_AWS_108 | Ensure IAM policies does not allow data exfiltration                                                |
| CKV_AWS_60  | Ensure IAM role allows only specific services or principals to assume it                            |
| CKV_AWS_274 | Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy                 |
| CKV_AWS_61  | Ensure AWS IAM policy does not allow assume role permission across all services                     |
| CKV_AWS_63  | Ensure no IAM policies documents allow "*" as a statement's actions                                 |
| CKV_AWS_62  | Ensure IAM policies that allow full "*-*" administrative privileges are not created                 |
| CKV_AWS_173 | Check encryption settings for Lambda environmental variable                                         |
| CKV_AWS_116 | Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)                          |
| CKV_AWS_50  | X-Ray tracing is enabled for Lambda                                                                 |
| CKV_AWS_115 | Ensure that AWS Lambda function is configured for function-level concurrent execution limit         |
| CKV_AWS_45  | Ensure no hard-coded secrets exist in lambda environment                                            |
| CKV_AWS_117 | Ensure that AWS Lambda function is configured inside a VPC                                          |
| CKV_AWS_272 | Ensure AWS Lambda function is configured to validate code-signing                                   |
| CKV2_AWS_5  | Ensure that Security Groups are attached to another resource                                        |
| CKV2_AWS_40 | Ensure AWS IAM policy does not allow full IAM privileges                                            |
| CKV2_AWS_40 | Ensure AWS IAM policy does not allow full IAM privileges                                            |

### Suppressed Best Practices

The following best practices are suppress:

| Id          | Policy                                                              |
|-------------|---------------------------------------------------------------------|
| CKV_AWS_158 | Ensure that CloudWatch Log Group is encrypted by KMS                |
| CKV_AWS_338 | Ensure CloudWatch log groups retains logs for at least 1 year       |
| CKV_AWS_111 | Ensure IAM policies does not allow write access without constraints |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/2.0.0 |
| <a name="module_cloudwatch_log"></a> [cloudwatch\_log](#module\_cloudwatch\_log) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs | rel/cloudwatchlogs/1.2.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_object.unsigned](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_signer_signing_job.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/signer_signing_job) | resource |
| [aws_sqs_queue.deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.lambda_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.signing_config_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.signing_profile_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | `"CloudWatchLogs"` | no |
| <a name="input_architectures"></a> [architectures](#input\_architectures) | (Optional) Instruction set architecture for your Lambda function.<br>  Valid values are ["x86\_64"] and ["arm64"].<br>  Default is ["arm64"].<br>  Removing this attribute, function's architecture stay the same. | `list(string)` | <pre>[<br>  "arm64"<br>]</pre> | no |
| <a name="input_code_signing_arn_ssm_parameter"></a> [code\_signing\_arn\_ssm\_parameter](#input\_code\_signing\_arn\_ssm\_parameter) | Name of the SSM Parameter containing the code signing profile.<br>  This should typically be left blank to use the default. | `string` | `""` | no |
| <a name="input_code_signing_name_ssm_parameter"></a> [code\_signing\_name\_ssm\_parameter](#input\_code\_signing\_name\_ssm\_parameter) | Name of the SSM Parameter containing the ARN of the code signing config.<br>    This should typically be left blank to use the default. | `string` | `""` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | `"CloudWatchLogs"` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) Description of what your Lambda Function does. | `string` | `""` | no |
| <a name="input_disable_code_signing"></a> [disable\_code\_signing](#input\_disable\_code\_signing) | WARNING! This should never be used in a production setting, this argument is for testing purposes<br>     only. Unsigned source is deleted from S3 after 30 days, meaning if you do use this in production<br>     your Lambda will stop functioning after 30 days. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | (Optional) Map of environment variables that are accessible from the function code during execution.<br>  If provided at least one key must be present. | `map(string)` | `null` | no |
| <a name="input_ephemeral_storage"></a> [ephemeral\_storage](#input\_ephemeral\_storage) | (Optional) The amount of Ephemeral storage (mounted as /tmp) to allocate for the Lambda Function in MB.<br>  This parameter is used to expand the total amount of Ephemeral storage available, beyond the default amount of 512MB. | `number` | `512` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | (Optional) Function entrypoint in your code. | `string` | `null` | no |
| <a name="input_is_lambda_at_edge"></a> [is\_lambda\_at\_edge](#input\_is\_lambda\_at\_edge) | Lambda@Edge has restrictions and limitations, setting this to true enables the restrictions so the Lambda can be used in a Lambda@Edge scenario. | `bool` | `false` | no |
| <a name="input_lambda_regional_environment"></a> [lambda\_regional\_environment](#input\_lambda\_regional\_environment) | Lambda Regional Environment Name, used to lookup regional code signing and S3 buckets. | `string` | `"WorkLoadConfig"` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | (Optional) Amount of memory in MB your Lambda Function can use at runtime.<br>  Defaults to 128. | `number` | `128` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the lambda function.  Used to name all dependent resources required by the function (e.g. DLQ, signing jobs, etc.) | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy to, using enhanced region support. Default is to use the provider configuration.<br>  Note that if `is_lambda_at_edge` is set to true, this variable is ignored and the resources<br>  will be deployed to us-east-1, as required by AWS. | `string` | `""` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | (Optional) Amount of reserved concurrent executions for this lambda function.<br>  A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations.<br>  Defaults to Unreserved Concurrency Limits -1. | `number` | `-1` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Identifier of the function's runtime. | `string` | n/a | yes |
| <a name="input_source_file"></a> [source\_file](#input\_source\_file) | The path of the lambda executable source file, such as a python script. The file will be zipped up and<br>  uploaded to the S3 bucket for signing, and then used by the Lambda.<br><br>  This is mutually exclusive with the `zip_file` variable. If both are set, `source_file` will be used. | `string` | `""` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | (Optional) Amount of time your Lambda Function has to run in seconds.<br>  Defaults to 3 seconds. | `number` | `3` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Controls the lambda's VPC settings.<br>    The enabled field controls whether the lambda runs in the private subnets of the VPC.  Defaults to false.<br>    The environment\_tag is used to lookup the VPC based on the VPCs tag structure.  Required if enabled is true. | <pre>object({<br>    enabled         = bool<br>    environment_tag = string<br>  })</pre> | <pre>{<br>  "enabled": false,<br>  "environment_tag": null<br>}</pre> | no |
| <a name="input_zip_file"></a> [zip\_file](#input\_zip\_file) | The path of the a lambda executable zip file. This could contain any executable or archive that is supported<br>  by the Lambda runtime. The file will be uploaded to the S3 bucket for signing, and then used by the Lambda.<br><br>  This is mutually exclusive with the `source_file` variable. If both are set, `source_file` will be used.<br><br>  If this is set, the `zip_file_hash` must also be included. | `string` | `""` | no |
| <a name="input_zip_file_hash"></a> [zip\_file\_hash](#input\_zip\_file\_hash) | The hash, md5 preferred, of the `zip_file`. Because of ordering issues with Terraform, this module cannot<br>    calculate the hash of the zip file itself using the Terraform md5file() function. If it did, the md5file()<br>    function gets called before the terraform plan is generated, which will fail if the zip\_file is not already<br>    on disk, like if it is downloaded using a terraform provider in the calling stack. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deadletter_queue_arn"></a> [deadletter\_queue\_arn](#output\_deadletter\_queue\_arn) | The ARN of the dead letter queue. |
| <a name="output_deadletter_queue_id"></a> [deadletter\_queue\_id](#output\_deadletter\_queue\_id) | The ID of the dead letter queue. |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role created for the lambda function |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the IAM role created for the lambda function |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | The ARN of the lambda function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | The name of the lambda function |
| <a name="output_lambda_invoke_arn"></a> [lambda\_invoke\_arn](#output\_lambda\_invoke\_arn) | The ARN to be used for invoking Lambda Function from API Gateway - to be used in `aws_api_gateway_integration`'s `uri`. |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | The ARN of the security group created for the lambda function if VPC attachment is used, else null. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the security group created for the lambda function if VPC attachment is used, else null. |
<!-- END_TF_DOCS -->
