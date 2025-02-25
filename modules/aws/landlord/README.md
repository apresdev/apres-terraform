# Landlord

This module deploys the Apres Landlord application. For further details on how to configure the application
and use it, see [https://github.com/apresdev/landlord](https://github.com/apresdev/landlord).

## Versioning

Landlord versions are tied into this module. To bump the container version:
1. Create a new branch of this module
2. Update the `container_image_uri` in [main.tf](./main.tf) wiht the new tag.
3. Copy the latest content of [landlord-openapi-ext.json](https://github.com/apresdev/landlord/tree/main/api) to
   [./api/landlord-openapi-ext.json](./api/landlord-openapi-ext.json).
4. Commit the changes, open a new Pull Request, setting the appropriate versioning.
5. Once merged, consume the new module version in the deploying code.

## TODO:
* Include AWS permissions
* Switch to using ARM64/Graviton
* Once the API spec is a release artifact get it from there instead of copying it here.
* Use versioning on the ECS container instead of a hash.

## AWS IAM Permissions
The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute:
*  `${AWS::AccountId}` with the Account ID where this is deployed
*  `${AWS::Region}` with the region where this is deployed, like `us-east-2`
*  `${name}` with the name passed in as the `name` variable
*  `${environment}` with the environment passed in as the `environment` variable

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "acm:RequestCertificate",
                "application-autoscaling:Describe*",
                "application-autoscaling:ListTagsForResource",
                "cloudwatch:Describe*",
                "cognito-idp:CreateUserPool",
                "cognito-idp:DescribeUserPoolDomain",
                "ec2:Describe*",
                "ec2:Get*",
                "ecs:CreateCluster",
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition",
                "elasticloadbalancing:Describe*",
                "kms:ListAliases",
                "logs:DescribeLogGroups",
                "route53:List*",
                "route53:Get*",
                "sns:GetSubscriptionAttributes"
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
                "kms:DescribeKey"
            ],
            "Resource": [
                "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/lambda",
                "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/apres/messaging",
                "arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/alias/aws/dynamodb"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:GetCodeSigningConfig"
            ],
            "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:code-signing-config:csc-03217076c40de791e"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketWebsite"
            ],
            "Resource": "arn:aws:s3:::${AWS::AccountId}-workloadconfig-${AWS::Region}-lambda-artifacts"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sqs:*"
            ],
            "Resource": [
                "arn:aws:sqs:${AWS::Region}:${AWS::AccountId}:${environment}-${name}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:ListTagsForResource"
            ],
            "Resource": "arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:${environment}-${name}-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress"
            ],
            "Resource": [
                "arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:security-group/*",
                "arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:vpc/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:ListTagsForCertificate"
            ],
            "Resource": [
                "arn:aws:acm:${AWS::Region}:${AWS::AccountId}:certificate/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:*"
            ],
            "Resource": "arn:aws:iam::${AWS::AccountId}:role/${environment}-${name}-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:*"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:${AWS::Region}:${AWS::AccountId}:loadbalancer/${environment}-${name}-*",
                "arn:aws:elasticloadbalancing:${AWS::Region}:${AWS::AccountId}:loadbalancer/app/${environment}-${name}-*/*",
                "arn:aws:elasticloadbalancing:${AWS::Region}:${AWS::AccountId}:loadbalancer/net/${environment}-${name}-*/*",
                "arn:aws:elasticloadbalancing:${AWS::Region}:${AWS::AccountId}:targetgroup/${environment}-${name}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy",
                "logs:ListTagsForResource"
            ],
            "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::${AWS::AccountId}-workloadconfig-${AWS::Region}-lambda-artifacts/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:*"
            ],
            "Resource": [
                "arn:aws:ecs:${AWS::Region}:${AWS::AccountId}:cluster/${environment}-${name}-*",
                "arn:aws:ecs:${AWS::Region}:${AWS::AccountId}:service/*/${environment}-${name}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:*"
            ],
            "Resource": "arn:aws:sns:${AWS::Region}:${AWS::AccountId}:${environment}-${name}-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "arn:aws:iam::${AWS::AccountId}:role/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "signer:StartSigningJob",
                "signer:DescribeSigningJob"
            ],
            "Resource": [
                "arn:aws:signer:${AWS::Region}:${AWS::AccountId}:/signing-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:*"
            ],
            "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:${environment}-${name}-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:*"
            ],
            "Resource": "arn:aws:cognito-idp:${AWS::Region}:${AWS::AccountId}:userpool/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:GetEventSourceMapping"
            ],
            "Resource": "arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:event-source-mapping:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "application-autoscaling:RegisterScalableTarget",
                "application-autoscaling:PutScalingPolicy"
            ],
            "Resource": "arn:aws:application-autoscaling:${AWS::Region}:${AWS::AccountId}:scalable-target/service/${environment}-${name}-*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "apigateway:*"
            ],
            "Resource": [
                "arn:aws:apigateway:${AWS::Region}::/vpclinks",
                "arn:aws:apigateway:${AWS::Region}::/vpclinks/*",
                "arn:aws:apigateway:${AWS::Region}::/restapis",
                "arn:aws:apigateway:${AWS::Region}::/apis/*/deployments",
                "arn:aws:apigateway:${AWS::Region}::/apis/*/deployments/*",
                "arn:aws:apigateway:${AWS::Region}::/apis/*/stages",
                "arn:aws:apigateway:${AWS::Region}::/apis/*/stages/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "wafv2:CreateWebACL",
                "wafv2:GetWebACL",
                "wafv2:ListTagsForResource",
                "wafv2:PutLoggingConfiguration",
                "wafv2:GetLoggingConfiguration"
            ],
            "Resource": [
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:REGIONAL/ipset/${environment}-${name}/*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:REGIONAL/managedruleset/${environment}-${name}/*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:REGIONAL/regexpatternset/${environment}-${name}/*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:REGIONAL/rulegroup/${environment}-${name}/*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:REGIONAL/webacl/${environment}-${name}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "wafv2:AssociateWebACL"
            ],
            "Resource": [
                "arn:aws:apigateway:${AWS::Region}::/restapis/*/stages/*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:regional/webacl/${environment}-${name}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "wafv2:GetWebACLForResource"
            ],
            "Resource": "arn:aws:apigateway:${AWS::Region}::/restapis/*/stages/*"
        }
    ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.59.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm_public_cert_api"></a> [acm\_public\_cert\_api](#module\_acm\_public\_cert\_api) | git@github.com:apresdev/apres-terraform.git//modules/aws/acm_public_cert | rel/acm_public_cert/2.0.0 |
| <a name="module_acm_public_cert_console"></a> [acm\_public\_cert\_console](#module\_acm\_public\_cert\_console) | git@github.com:apresdev/apres-terraform.git//modules/aws/acm_public_cert | rel/acm_public_cert/2.0.0 |
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |
| <a name="module_landlord_api_ecs"></a> [landlord\_api\_ecs](#module\_landlord\_api\_ecs) | git@github.com:apresdev/apres-terraform.git//modules/aws/ecs | rel/ecs/2.1.3 |
| <a name="module_landlord_api_gateway"></a> [landlord\_api\_gateway](#module\_landlord\_api\_gateway) | git@github.com:apresdev/apres-terraform.git//modules/aws/api_gateway_rest | rel/api_gateway_rest/1.1.0 |
| <a name="module_landlord_cdc_publisher"></a> [landlord\_cdc\_publisher](#module\_landlord\_cdc\_publisher) | git@github.com:apresdev/apres-terraform.git//modules/aws/dynamodb_sns_publisher | rel/dynamodb_sns_publisher/0.2.0 |
| <a name="module_landlord_cdc_topic"></a> [landlord\_cdc\_topic](#module\_landlord\_cdc\_topic) | git@github.com:apresdev/apres-terraform.git//modules/aws/sns | rel/sns/1.0.0 |
| <a name="module_landlord_console_ecs"></a> [landlord\_console\_ecs](#module\_landlord\_console\_ecs) | git@github.com:apresdev/apres-terraform.git//modules/aws/ecs | rel/ecs/2.1.3 |
| <a name="module_landlord_dynamo"></a> [landlord\_dynamo](#module\_landlord\_dynamo) | git@github.com:apresdev/apres-terraform.git//modules/aws/dynamodb | rel/dynamodb/1.0.0 |
| <a name="module_landlord_pre_token_generation_lambda"></a> [landlord\_pre\_token\_generation\_lambda](#module\_landlord\_pre\_token\_generation\_lambda) | git::git@github.com:apresdev/apres-terraform.git//modules/aws/lambda | rel/lambda/0.6.0 |
| <a name="module_landlord_sns_sqs_subscription"></a> [landlord\_sns\_sqs\_subscription](#module\_landlord\_sns\_sqs\_subscription) | git@github.com:apresdev/apres-terraform.git//modules/aws/sns_sqs_subscription | rel/sns_sqs_subscription/0.1.0 |
| <a name="module_landlord_sync_queue"></a> [landlord\_sync\_queue](#module\_landlord\_sync\_queue) | git@github.com:apresdev/apres-terraform.git//modules/aws/sqs | rel/sqs/1.0.0 |
| <a name="module_landlord_waf"></a> [landlord\_waf](#module\_landlord\_waf) | git@github.com:apresdev/apres-terraform.git//modules/aws/waf | rel/waf/1.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cognito_user_pool.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_cognito_user_pool_ui_customization.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_ui_customization) | resource |
| [aws_iam_role.landlord_sms_cognito_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.landlord_sms_cognito_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_permission.with_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.console](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [random_uuid.sms_external_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_admin_email"></a> [app\_admin\_email](#input\_app\_admin\_email) | The email address of an app administrator, used when sending alert notifications | `string` | n/a | yes |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The name of the app using landlord. Used in various UI displays when authenticating | `string` | n/a | yes |
| <a name="input_app_url"></a> [app\_url](#input\_app\_url) | The base URL of the app with its protocol scheme, used by Landlord & Cognito to redirect to after login | `string` | n/a | yes |
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_cognito_callback_urls"></a> [cognito\_callback\_urls](#input\_cognito\_callback\_urls) | List of callback URLs that are allowed as destinations after Cognito authentication. | `list(string)` | `[]` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_custom_domain_prefix"></a> [custom\_domain\_prefix](#input\_custom\_domain\_prefix) | The custom domain prefix for the Cognito Hosted UI. Note this must be globally unique to all customers and<br/>    regions, so pick a unique one. The resulting domain will be<br/>    {var.custom\_domain\_prefix}.auth.{current region}.amazoncognito.com. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_hosted_ui_css_filename"></a> [hosted\_ui\_css\_filename](#input\_hosted\_ui\_css\_filename) | Custom CSS to be applied to the hosted UI (classic) for branding, provided as a file path to the CSS file.<br/>  If not provided, the default AWS branding will be used. See<br/>  https://docs.aws.amazon.com/cognito/latest/developerguide/hosted-ui-classic-branding.html<br/>  for details. | `string` | `""` | no |
| <a name="input_hosted_ui_logo_filename"></a> [hosted\_ui\_logo\_filename](#input\_hosted\_ui\_logo\_filename) | The uploaded logo image for the UI customization, provided as  file path to the image file.<br/>Drift detection is not possible for this argument. If not provided, the default AWS branding will be used. See<br/>https://docs.aws.amazon.com/cognito/latest/developerguide/hosted-ui-classic-branding.html<br/>for details. | `string` | `""` | no |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | The name of the hosted zone in Route53 in which to create the Route53 entries for the load balancers. This<br/>  will also be used to create the certificate names. Two names will be created:<br/>  * {var.name}.{var.hosted\_zone\_name}<br/>  * {var.name}-api.{var.hosted\_zone\_name}<br/>  For example, if var.name is set to "landlord" and var.hosted\_zone\_name is set to "example.com", the following<br/>  certificates and Route53 entries will be created:<br/>  * landlord.example.com<br/>  * landlord-api.example.com | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_sms_aws_region"></a> [sms\_aws\_region](#input\_sms\_aws\_region) | The AWS region where SMS is configured (via SNS). If this is left blank, the current region where<br/>  the stack is deployed will be used. See<br/>  https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-sms-settings.html<br/>  on how to setup SMS for Cognito. | `string` | n/a | yes |
| <a name="input_vpc_environment_tag"></a> [vpc\_environment\_tag](#input\_vpc\_environment\_tag) | The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC<br/>    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more<br/>    if it was configured that way. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_public_cert_api_arn"></a> [acm\_public\_cert\_api\_arn](#output\_acm\_public\_cert\_api\_arn) | The ARN of the ACM certificate for the API. |
| <a name="output_acm_public_cert_console_arn"></a> [acm\_public\_cert\_console\_arn](#output\_acm\_public\_cert\_console\_arn) | The ARN of the ACM certificate for the console. |
| <a name="output_api_domain_name"></a> [api\_domain\_name](#output\_api\_domain\_name) | The domain name of the API. |
| <a name="output_api_ecs_cluster_name"></a> [api\_ecs\_cluster\_name](#output\_api\_ecs\_cluster\_name) | The name of the ECS cluster for the API. |
| <a name="output_api_ecs_service_name"></a> [api\_ecs\_service\_name](#output\_api\_ecs\_service\_name) | The name of the ECS service for the API. |
| <a name="output_api_gateway_arn"></a> [api\_gateway\_arn](#output\_api\_gateway\_arn) | The ARN of the API Gateway. |
| <a name="output_api_gateway_invoke_url"></a> [api\_gateway\_invoke\_url](#output\_api\_gateway\_invoke\_url) | The invoke URL of the API Gateway. |
| <a name="output_api_load_balancer_arn"></a> [api\_load\_balancer\_arn](#output\_api\_load\_balancer\_arn) | The ARN of the load balancer for the API. |
| <a name="output_api_load_balancer_fqdn"></a> [api\_load\_balancer\_fqdn](#output\_api\_load\_balancer\_fqdn) | The FQDN of the load balancer for the API. |
| <a name="output_cdc_sync_queue_arn"></a> [cdc\_sync\_queue\_arn](#output\_cdc\_sync\_queue\_arn) | The ARN of the CDC sync SQS queue. |
| <a name="output_cdc_sync_queue_name"></a> [cdc\_sync\_queue\_name](#output\_cdc\_sync\_queue\_name) | The name of the CDC sync SQS queue. |
| <a name="output_console_domain_name"></a> [console\_domain\_name](#output\_console\_domain\_name) | The domain name of the console. |
| <a name="output_console_ecs_cluster_name"></a> [console\_ecs\_cluster\_name](#output\_console\_ecs\_cluster\_name) | The name of the ECS cluster for the console. |
| <a name="output_console_ecs_service_name"></a> [console\_ecs\_service\_name](#output\_console\_ecs\_service\_name) | The name of the ECS service for the console. |
| <a name="output_console_load_balancer_arn"></a> [console\_load\_balancer\_arn](#output\_console\_load\_balancer\_arn) | The ARN of the load balancer for the console. |
| <a name="output_console_load_balancer_fqdn"></a> [console\_load\_balancer\_fqdn](#output\_console\_load\_balancer\_fqdn) | The FQDN of the load balancer for the console. |
<!-- END_TF_DOCS -->