# WAF v2

This creates a WAFv2 ACL with configurable rule sets, and associates it with any supported AWS resource. It is referred
to as "WAF" throughout but only supports v2.

This was in part borrowed from and inspired by https://github.com/trussworks/terraform-aws-wafv2/tree/main.

# AWS IAM Permissions

The following permissions are required to use this module, shown as a Policy snippet in JSON.
Substitute `${AWS::AccountId}` with the Account ID where this is deployed, `${AWS::Region}` with
the region such as `us-east-2`, and `${name}` with the name passed in.

NOTE: The statement with Sid `AssociateWAF` allows the association of the WAF to another resource, but that other resource
is not listed in the example, you will need to add it else the association will fail.

```json

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ManageCWLforWAF",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy",
                "logs:ListTagsForResource",
                "logs:DeleteLogGroup"
            ],
            "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:aws-waf-logs-*"
        },
        {
            "Sid": "ManageWAF",
            "Effect": "Allow",
            "Action": [
                "wafv2:CreateWebACL",
                "wafv2:GetWebACL",
                "wafv2:DeleteWebACL",
                "wafv2:ListTagsForResource",
                "wafv2:PutLoggingConfiguration",
                "wafv2:GetLoggingConfiguration",
                "wafv2:DeleteLoggingConfiguration"
            ],
            "Resource": [
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:*/ipset/${name}*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:*/managedruleset/${name}*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:*/regexpatternset/${name}*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:*/rulegroup/${name}*",
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:*/webacl/${name}*"
            ]
        },
        {
            "Sid": "WAFandIAMforCWL",
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "arn:aws:iam::${AWS::AccountId}:role/*"
        },
        {
            "Sid": "AssociateWAF",
            "Effect": "Allow",
            "Action": [
                "wafv2:AssociateWebACL"
                "wafv2:GetWebACLForResource",
                "wafv2:DisassociateWebACL"
            ],
            "Resource": [
                "arn:aws:wafv2:${AWS::Region}:${AWS::AccountId}:*/webacl/${name}*"
            ]
        }
    ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.1, <2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.59.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cwl_waf"></a> [cwl\_waf](#module\_cwl\_waf) | git@github.com:apresdev/apres-terraform.git//modules/aws/cloudwatchlogs | rel/cloudwatchlogs/1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_wafv2_web_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_associate_resource_arn"></a> [associate\_resource\_arn](#input\_associate\_resource\_arn) | The ARN of the resource to associate with the web ACL. The resource can be any supported<br>    service such as an Application Load Balancer, API Gateway, AWS AppSync, or an Amazon CloudFront.<br><br>    Note: the README contains a list of IAM permissions, this ARN needs to be added to the statement<br>    with the Sid `AssociateWAF` else the association will fail. | `string` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | Component name, used for tagging AWS resources. | `string` | n/a | yes |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | The action to perform if none of the rules contained in the WebACL match. | `string` | `"allow"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name, used for naming and tagging AWS resources. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_filtered_header_rule"></a> [filtered\_header\_rule](#input\_filtered\_header\_rule) | HTTP header to filter . Currently supports a single header type and multiple header values. | <pre>object({<br>    header_types  = list(string)<br>    priority      = number<br>    header_value  = string<br>    action        = string<br>    search_string = string<br>  })</pre> | <pre>{<br>  "action": "block",<br>  "header_types": [],<br>  "header_value": "",<br>  "priority": 1,<br>  "search_string": ""<br>}</pre> | no |
| <a name="input_group_rules"></a> [group\_rules](#input\_group\_rules) | List of WAFv2 Rule Groups. | <pre>list(object({<br>    name            = string<br>    arn             = string<br>    priority        = number<br>    override_action = string<br>  }))</pre> | `[]` | no |
| <a name="input_ip_rate_based_rule"></a> [ip\_rate\_based\_rule](#input\_ip\_rate\_based\_rule) | A rate-based rule tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span | <pre>object({<br>    name          = string<br>    priority      = number<br>    limit         = number<br>    action        = string<br>    response_code = optional(number, 403)<br>  })</pre> | `null` | no |
| <a name="input_ip_rate_url_based_rules"></a> [ip\_rate\_url\_based\_rules](#input\_ip\_rate\_url\_based\_rules) | A rate and url based rules tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span | <pre>list(object({<br>    name                  = string<br>    priority              = number<br>    limit                 = number<br>    action                = string<br>    response_code         = optional(number, 403)<br>    search_string         = string<br>    positional_constraint = string<br>  }))</pre> | `[]` | no |
| <a name="input_ip_sets_rule"></a> [ip\_sets\_rule](#input\_ip\_sets\_rule) | A rule to detect web requests coming from particular IP addresses or address ranges. | <pre>list(object({<br>    name          = string<br>    priority      = number<br>    ip_set_arn    = string<br>    action        = string<br>    response_code = optional(number, 403)<br>  }))</pre> | `[]` | no |
| <a name="input_managed_rules"></a> [managed\_rules](#input\_managed\_rules) | List of Managed WAF rules. | <pre>list(object({<br>    name            = string<br>    priority        = number<br>    override_action = string<br>    vendor_name     = string<br>    version         = optional(string)<br>    rule_action_override = list(object({<br>      name          = string<br>      action_to_use = string<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "name": "AWSManagedRulesCommonRuleSet",<br>    "override_action": "none",<br>    "priority": 10,<br>    "rule_action_override": [],<br>    "vendor_name": "AWS"<br>  },<br>  {<br>    "name": "AWSManagedRulesAmazonIpReputationList",<br>    "override_action": "none",<br>    "priority": 20,<br>    "rule_action_override": [],<br>    "vendor_name": "AWS"<br>  },<br>  {<br>    "name": "AWSManagedRulesKnownBadInputsRuleSet",<br>    "override_action": "none",<br>    "priority": 30,<br>    "rule_action_override": [],<br>    "vendor_name": "AWS"<br>  },<br>  {<br>    "name": "AWSManagedRulesSQLiRuleSet",<br>    "override_action": "none",<br>    "priority": 40,<br>    "rule_action_override": [],<br>    "vendor_name": "AWS"<br>  },<br>  {<br>    "name": "AWSManagedRulesLinuxRuleSet",<br>    "override_action": "none",<br>    "priority": 50,<br>    "rule_action_override": [],<br>    "vendor_name": "AWS"<br>  },<br>  {<br>    "name": "AWSManagedRulesUnixRuleSet",<br>    "override_action": "none",<br>    "priority": 60,<br>    "rule_action_override": [],<br>    "vendor_name": "AWS"<br>  }<br>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to create resources | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources, used for tagging AWS resources. | `string` | `"Engineering"` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | The scope of this Web ACL. Valid options: CLOUDFRONT, REGIONAL. If scope is CLOUDFRONT,<br>   the WAF must be created in us-east-1. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_waf_arn"></a> [waf\_arn](#output\_waf\_arn) | The ARN of the WAF ACL |
<!-- END_TF_DOCS -->