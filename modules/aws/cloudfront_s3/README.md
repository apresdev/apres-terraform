# CloudFront Distribution with S3 origin

Create a CloudFront Distribution with an S3 bucket as origin (serving content).

The S3 bucket is created with a customer managed KMS key, and the CloudFront Distribution is given
access to use that KMS key.

The CloudFront Distribution writes logs to a second bucket, using the same name as the primary bucket
but with "-logs" appended.

The WAF, for now, has three default rulesets, managed by AWS:

- AWSManagedRulesCommonRuleSet
- AWSManagedRulesKnownBadInputsRuleSet
- AWSManagedRulesAnonymousIpList

Note that it typically takes five minutes to create or destroy a distribution. The unit
tests take at least 10 minutes to run because of that, and if run manually you
should add a `-timeout 30m` on the CLI.

Once the stack has deployed, upload your static files to the S3 bucket named in output `s3_bucket_name`,
including the file specified by the `default_root_object` variable, and then browse to the URL given in
the output `cloudfront_domain_name`.

## Prerequisites

If you do not specify the `waf_arn` variable, the WAF will be created in us-east-1, because that's where a CloudFront
WAF must be created, see the discussion at [WAF and us-east-1](#waf-and-us-east-1). You must deploy the Apres `cloudwatchlogs_regional` in us-east-1 for successful deployment of this
module.

## WAF and us-east-1

A CloudFront WAF can only be created in the us-east-1 region, regardless where the other resources are deployed,
this module implements that.
Because of that and limitations in how Terraform handles multiple providers, the WAF configuration, if not overridden
by setting the `waf_arn` variable, is done in a sub-module so that a provider alias can be passed in.

## Domain names - Certificates, us-east-1, and Route53

Certificates used in CloudFront distributions must be created in us-east-1. Because of that and that this
module can be deployed in any region, this module does not create the certificate.  You will need to create
the certificate in a separate stack, using the [acm_public_cert](../acm_public_cert/) module. Then use
the `acm_certificate_arn` to specify the certificate ARN.

Certificates and Route53 are a complicated matter. For a Cloudfront distribution to work with more than one
domain name, the following needs be true:
* The domain name needs to be either the primary domain name on the certificate, or listed as a
  Subject Alternative Domain (SAN), or Alias.
* The domain name needs to be in Route53 pointing to the Cloudfront distribution.

For example, let's assume two domain names should work: `dashboard.prod.example.com`, and `dashboard.example.com`.

If the `example.com` domain is hosted in Route53 in the AWS account where the module is deployed, then
create the certificate, and set the following variables:

```hcl
module "cloudfront_s3" {
  # ...
  hosted_zone_name    = "example.com"
  primary_domain      = "dashboard.prod.example.com"
  alias_domains       = [ "dashboard.example.com" ]
  acm_certificate_arn = "arn:... " # the arn to the created certificate
  # ...
}
```

In that scenario two Route53 alias entries will be created in the `example.com` hosted zone
for `dashboard.prod.example.com` and `dashboard.example.com`

However if the domain `prod.example.com` is hosted in Route53 in the AWS account where the module is deployed,
the Route53 entries for the `dashboard.example.com` cannot be created. In that
case you will need to:
1. Create the certificate yourself in us-east-1, and manage the verification yourself.
2. Pass the ARN of the certificate into the `acm_certificate_arn` variable
3. The `dashboard.example.com` Route53 entry will not be created, you will need to add that to whichever system manages the `example.com` domain.

In all cases, the Route53 entries are "Alias" entries in AWS terminology, since they alias a CloudFront distribution,
but the actual DNS recores are "A" records, not "CNAME" as you might expect. See
[Choosing between alias and non-alias records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html)
for a detailed discussion.

## S3 Bucket Replication

It may be desireable to replicate the contents of the underlying S3 bucket to another bucket. The replication
is done via the S3 module, using the same arguments. See the [S3 module README](../s3/README.md) for details
on the replication.

## TODO

* Examine WAF rules: is the default set enough?
* Not sure CloudFront logging is working, verify that.
* Investigate real-time logging for CloudFront: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/real-time-logs.html
* Not sure about caching

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute the following:
* `${AWS::AccountId}` with the Account ID where this stack is deployed.
* `${AWS::Region}` with the AWS Region where this stack is deployed, like `us-east-2`
* `${environment}` with the lower case of the variable `var.environment`
* `${name}` with the lower case of the variable `var.name`

Some of the permissions have `us-east-1` hardcoded, for WAF deployment, see discussion at
[WAF and us-east-1](#waf-and-us-east-1)

```json
{
  "Effect": "Allow",
  "Action": [
     "s3:*"
  ],
  "Resource": [
    "arn:aws:s3:::${AWS::AccountId}-${environment}-${AWS::Region}-${name}*"
    "arn:aws:s3:::${AWS::AccountId}-${environment}-${AWS::Region}-${name}*/*"
  ]
},
{
  "Effect": "Allow",
  "Action": "kms:*",
  "Resource": [
    "arn:aws:kms:${AWS:Region}:key/*",
    "arn:aws:kms:us-east-1:key/*"
  ]
},
{
  "Effect": "Allow",
  "Action": [
    "wafv2:*"
  ],
  "Resource": [
    "arn:aws:wafv2:us-east-1:${AWS::AccountId}:*"
  ]
},
{
  "Effect": "Allow",
  "Action": [
    "iam:CreateServiceLinkedRole"
  ],
  "Resource": [
    "arn:aws:iam::${AWS::AccountId}:role/*"
  ]
},
{
  "Effect": "Allow",
  "Action": [
    "cloudfront:*"
  ],
  "Resource": [
    "arn:aws:cloudfront::${AWS::AccountId}:distribution/*"
  ]
}
{
  "Effect": "Allow",
  "Action": [
    "logs:*"
  ],
  "Resource": [
    "arn:aws:cloudfront:us-east-1:${AWS::AccountId}:log-group:aws-waf-logs-*"
  ]
},
{
  "Effect": "Allow",
  "Action": [
    "logs:*"
  ],
  "Resource": [
    "arn:aws:cloudfront:${AWS::Region}:${AWS::AccountId}:log-group:*"
  ]
},
{
  "Effect": "Allow",
  "Action": [
    "route53:*"
  ],
  "Resource": [ "*" ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.86.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.86.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apres_names"></a> [apres\_names](#module\_apres\_names) | git@github.com:apresdev/apres-terraform.git//modules/aws/apres_names | rel/apres_names/1.0.0 |
| <a name="module_s3"></a> [s3](#module\_s3) | git@github.com:apresdev/apres-terraform.git//modules/aws/s3 | rel/s3/4.1.0 |
| <a name="module_s3_logs"></a> [s3\_logs](#module\_s3\_logs) | git@github.com:apresdev/apres-terraform.git//modules/aws/s3 | rel/s3/4.1.0 |
| <a name="module_waf"></a> [waf](#module\_waf) | git@github.com:apresdev/apres-terraform.git//modules/aws/waf | rel/waf/1.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_cache_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_kms_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_key_policy.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_route53_record.aliases](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket_acl.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_cloudfront_log_delivery_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_log_delivery_canonical_user_id) | data source |
| [aws_iam_policy_document.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logging_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_destination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of an ACM SSL Certificate to use with the distribution. If not set, the default<br/>    CloudFront certificate will be used. Note the ACM Certificate must be in us-east-1!<br/><br/>    There are several reasons to create a certificate outside this module:<br/>    1. The cloudfront module is not deployed to us-east-1 - in that case you must create the certificate<br/>       in us-east-1 and pass in ARN here.<br/>    2. One or more of the entries in `alias_domains` is not in the domain specified by the `hosted_zone_name`,<br/>       which means that automatic creation of the Route53 DNS records required for domain validation cannot be<br/>       created - in that case you must create the certificate in us-east-1, manage the DNS records manually, and<br/>       pass in the ARN here. | `string` | `""` | no |
| <a name="input_alias_domains"></a> [alias\_domains](#input\_alias\_domains) | List of aliases to apply to the CloudFront distribution. Note that if an entry does not<br/>    end with the `hosted_zone_name`, no alias record will be created in Route53, since this<br/>    module will not know where the domain is hosted.<br/><br/>    For example, if:<br/>    * hosted\_zone\_name = "example.com"<br/>    * primary\_domain = "something.example.com"<br/>    * alias\_domains = ["www.example.com", "somethingelse.com"]<br/>    Then:<br/>    * The alias record for `something.example.com` and `www.example.com` will be created in Route53<br/>      in the `example.com` domain, but not for `somethingelse.com`.<br/><br/>    Note: All alias domains should be in the subject\_alternative\_name list of the ACM certificate. | `list(string)` | `[]` | no |
| <a name="input_allow_browser_uploads"></a> [allow\_browser\_uploads](#input\_allow\_browser\_uploads) | Enables the CORS rules in the S3 bucket to allow pre-signed PutObject requests from the browser. | `bool` | `false` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_cloudfront_cache_allowed_methods"></a> [cloudfront\_cache\_allowed\_methods](#input\_cloudfront\_cache\_allowed\_methods) | List of allowed HTTP methods for the CloudFront cache policy. Must be one of:<br/>  * ["HEAD", "GET"] or<br/>  * ["HEAD", "GET", "OPTIONS"] or<br/>  * ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"] | `list(string)` | <pre>[<br/>  "HEAD",<br/>  "DELETE",<br/>  "POST",<br/>  "GET",<br/>  "OPTIONS",<br/>  "PUT",<br/>  "PATCH"<br/>]</pre> | no |
| <a name="input_cloudfront_cache_cached_methods"></a> [cloudfront\_cache\_cached\_methods](#input\_cloudfront\_cache\_cached\_methods) | List of cached HTTP methods for the CloudFront cache policy. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS"<br/>]</pre> | no |
| <a name="input_cloudfront_custom_error_responses"></a> [cloudfront\_custom\_error\_responses](#input\_cloudfront\_custom\_error\_responses) | Custom error responses. See<br/>  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GeneratingCustomErrorResponses.html | `list(any)` | `[]` | no |
| <a name="input_cloudfront_custom_spa_error_responses"></a> [cloudfront\_custom\_spa\_error\_responses](#input\_cloudfront\_custom\_spa\_error\_responses) | Custom error responses for SPA applications. See<br/>  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GeneratingCustomErrorResponses.html | `list(any)` | `[]` | no |
| <a name="input_cloudfront_geo_restrictions_locations"></a> [cloudfront\_geo\_restrictions\_locations](#input\_cloudfront\_geo\_restrictions\_locations) | List of locations to apply to the CloudFront distribution, in form of ISO-3166 Country Codes, see<br/>  http://www.iso.org/iso/country_codes/iso_3166_code_lists/country_names_and_code_elements.html for a list.<br/>  Only valid if cloudfront\_geo\_restrictions\_type is 'blacklist' or 'whitelist'.<br/><br/>  Example: ["US", "CA"] | `list(string)` | `[]` | no |
| <a name="input_cloudfront_geo_restrictions_type"></a> [cloudfront\_geo\_restrictions\_type](#input\_cloudfront\_geo\_restrictions\_type) | Type of geo restrictions to apply to the CloudFront distribution, one of 'none', 'blacklist', or 'whitelist'. | `string` | `"none"` | no |
| <a name="input_cloudfront_logs_expiration"></a> [cloudfront\_logs\_expiration](#input\_cloudfront\_logs\_expiration) | Number of days before logs are deleted. | `number` | `365` | no |
| <a name="input_cloudfront_logs_transition_glacier"></a> [cloudfront\_logs\_transition\_glacier](#input\_cloudfront\_logs\_transition\_glacier) | Number of days before logs are transitioned to Glacier storage class. | `number` | `90` | no |
| <a name="input_cloudfront_logs_transition_ia"></a> [cloudfront\_logs\_transition\_ia](#input\_cloudfront\_logs\_transition\_ia) | Number of days before logs are transitioned to IA storage class. | `number` | `30` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | Price class for the CloudFront distribution. See<br/>  https://aws.amazon.com/cloudfront/pricing/ for details | `string` | `"PriceClass_200"` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | `"CloudFrontS3"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Default root file to serve. See<br/>  https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DefaultRootObject.html | `string` | `"index.html"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | The name of the hosted zone in Route53 in which to create the<br/>    alias records for the CloudFront distribution. If not specified, creation of Route53 aliases using<br/>    the primary\_domain and alias\_domains will be skipped. | `string` | `""` | no |
| <a name="input_is_spa"></a> [is\_spa](#input\_is\_spa) | Whether the site is a Single Page Application and 403, 404 error messages should be re-directed to the root object | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the distribution, used to create resources including the S3 bucket | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_primary_domain"></a> [primary\_domain](#input\_primary\_domain) | The primary domain name for the CloudFront distribution. A Route53 alias will be created using this domain.<br/>    This name will be the first alias in the aliases list.<br/><br/>    Note: This domain must be the domain name or in the subject\_alternative\_name list of the ACM certificate. | `string` | `""` | no |
| <a name="input_replication_destination_config"></a> [replication\_destination\_config](#input\_replication\_destination\_config) | Object to configure the S3 bucket as the destination of replication. All attributes are ignored if `enabled` is false.<br/><br/>  Attributes:<br/>  * enabled - set to true if this is the destination bucket, else replication will not be enabled.<br/>  * source\_bucket\_account - The AWS Account ID where the source bucket is homed.<br/>  * source\_bucket\_arn - The ARN of the source bucket.<br/>  * source\_service\_role\_arn - The ARN of the service role that will be used to replicate objects. Note that<br/>    depending on how the role was created, it could be two different patterns:<br/>    * arn:aws:iam::account-id:role/role-name - created with the CLI or via this module<br/>    * arn:aws:iam::account-id:role/service-role/role-name - created with the Console<br/>    See the output `replication_source_iam_role` for the IAM role created by this module on the source bucket. | <pre>object({<br/>    enabled                 = bool<br/>    source_bucket_account   = string<br/>    source_bucket_arn       = string<br/>    source_service_role_arn = string<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "source_bucket_account": "",<br/>  "source_bucket_arn": "",<br/>  "source_service_role_arn": ""<br/>}</pre> | no |
| <a name="input_replication_source_config"></a> [replication\_source\_config](#input\_replication\_source\_config) | Object to configure the S3 bucket as the source of replication. All attributes are ignored if `enabled` is false.<br/>  Attributes:<br/>  * enabled - set to true if this is the source bucket, else replication will not be enabled.<br/>  * destination\_account\_id - The AWS Account ID where the destination bucket is homed.<br/>  * destination\_bucket\_arn - The ARN of the destination bucket.<br/>  * destination\_kms\_key\_arn - The ARN of the KMS key to use for server-side encryption in the destination bucket.<br/>    This _may_ be the KMS Alias if the source and bucket are in the same account.<br/>  * destination\_region - The region of the destination bucket.<br/>  * owner\_translation - If true, ownership (AWS Account ID) of the object in the destination bucket will be set to the owner<br/>    of the destination bucket. If false, the owner of the object written in the destination bucket will be that<br/>    of the source bucket.<br/>  * replication\_prefix - The prefix to apply to the replication configuration, default is everything. Include wildcards<br/>    if necessary. For example "Tax/" or "Tax*" are both legitimate.<br/>  * replicate\_delete\_markers - Flag to indicate if delete markers should be replicated, which means objects<br/>    deleted in the source bucket will also be deleted in the destination bucket. | <pre>object({<br/>    enabled                  = bool<br/>    destination_account_id   = string<br/>    destination_bucket_arn   = string<br/>    destination_kms_key_arn  = string<br/>    destination_region       = string<br/>    owner_translation        = bool<br/>    replicate_delete_markers = bool<br/>    replication_prefix       = string<br/>  })</pre> | <pre>{<br/>  "destination_account_id": "",<br/>  "destination_bucket_arn": "",<br/>  "destination_kms_key_arn": "",<br/>  "destination_region": "",<br/>  "enabled": false,<br/>  "owner_translation": true,<br/>  "replicate_delete_markers": false,<br/>  "replication_prefix": ""<br/>}</pre> | no |
| <a name="input_waf_arn"></a> [waf\_arn](#input\_waf\_arn) | ARN of the WAF to attach to the CloudFront distribution. The provided ARN must be of a WAF v2<br/>    with scope "CLOUDFRONT" deployed in us-east-1.<br/><br/>    If not set, a default WAF with the following rulesets will be created:<br/>    * AWSManagedRulesCommonRuleSet<br/>    * AWSManagedRulesKnownBadInputsRuleSet<br/>    * AWSManagedRulesAnonymousIpList | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | Domain name of the CloudFront distribution |
| <a name="output_cloudfront_distribution_hosted_zone_id"></a> [cloudfront\_distribution\_hosted\_zone\_id](#output\_cloudfront\_distribution\_hosted\_zone\_id) | Hosted zone ID of the CloudFront distribution, required for creating alias records. |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | ID of the CloudFront distribution |
| <a name="output_replication_source_service_role_arn"></a> [replication\_source\_service\_role\_arn](#output\_replication\_source\_service\_role\_arn) | The IAM role name for the replication source.  This is only created if replication is enabled and this<br/>    is the source bucket. This Role ARN is needed to allow the destination bucket to replicate from this bucket. |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | Global domain name of the S3 bucket containing the website content |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket containing the website content |
| <a name="output_s3_bucket_regional_domain_name"></a> [s3\_bucket\_regional\_domain\_name](#output\_s3\_bucket\_regional\_domain\_name) | Regional domain name of the S3 bucket containing the website content |
| <a name="output_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#output\_s3\_kms\_key\_arn) | ARN of the KMS key used to encrypt the S3 bucket |
| <a name="output_s3_logs_bucket_domain_name"></a> [s3\_logs\_bucket\_domain\_name](#output\_s3\_logs\_bucket\_domain\_name) | Global domain name of the S3 bucket containing the CloudFront logs |
| <a name="output_s3_logs_bucket_name"></a> [s3\_logs\_bucket\_name](#output\_s3\_logs\_bucket\_name) | Name of the S3 bucket containing the CloudFront logs |
| <a name="output_s3_logs_bucket_regional_domain_name"></a> [s3\_logs\_bucket\_regional\_domain\_name](#output\_s3\_logs\_bucket\_regional\_domain\_name) | Regional domain name of the S3 bucket containing the CloudFront logs |
| <a name="output_waf_arn"></a> [waf\_arn](#output\_waf\_arn) | ARN of the WAF attached to the CloudFront distribution |
<!-- END_TF_DOCS -->
