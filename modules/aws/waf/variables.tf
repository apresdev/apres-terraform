variable "name" {
  description = "Name used to create resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_ ]+$", var.name))
    error_message = "Name must be alphanumeric and can contain hyphens and underscores."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  default     = "Engineering"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "environment" {
  description = "Environment Name, used for naming and tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}

variable "scope" {
  type        = string
  description = <<EOF
   The scope of this Web ACL. Valid options: CLOUDFRONT, REGIONAL. If scope is CLOUDFRONT,
   the WAF must be created in us-east-1.
  EOF
  validation {
    condition     = can(regex("^(CLOUDFRONT|REGIONAL)$", var.scope))
    error_message = "Scope must be one of: CLOUDFRONT, REGIONAL"
  }
}

variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    vendor_name     = string
    version         = optional(string)
    rule_action_override = list(object({
      name          = string
      action_to_use = string
    }))
  }))
  description = "List of Managed WAF rules."
  default = [
    {
      name                 = "AWSManagedRulesCommonRuleSet",
      priority             = 10
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesAmazonIpReputationList",
      priority             = 20
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesKnownBadInputsRuleSet",
      priority             = 30
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesSQLiRuleSet",
      priority             = 40
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesLinuxRuleSet",
      priority             = 50
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesUnixRuleSet",
      priority             = 60
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    }
  ]
}

variable "ip_sets_rule" {
  type = list(object({
    name          = string
    priority      = number
    ip_set_arn    = string
    action        = string
    response_code = optional(number, 403)
  }))
  description = "A rule to detect web requests coming from particular IP addresses or address ranges."
  default     = []
}

variable "ip_rate_based_rule" {
  type = object({
    name          = string
    priority      = number
    limit         = number
    action        = string
    response_code = optional(number, 403)
  })
  description = "A rate-based rule tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span"
  default     = null
}

variable "ip_rate_url_based_rules" {
  type = list(object({
    name                  = string
    priority              = number
    limit                 = number
    action                = string
    response_code         = optional(number, 403)
    search_string         = string
    positional_constraint = string
  }))
  description = "A rate and url based rules tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span"
  default     = []
}

variable "filtered_header_rule" {
  type = object({
    header_types  = list(string)
    priority      = number
    header_value  = string
    action        = string
    search_string = string
  })
  description = "HTTP header to filter . Currently supports a single header type and multiple header values."
  default = {
    header_types  = []
    priority      = 1
    header_value  = ""
    action        = "block"
    search_string = ""
  }
}

variable "group_rules" {
  type = list(object({
    name            = string
    arn             = string
    priority        = number
    override_action = string
  }))
  description = "List of WAFv2 Rule Groups."
  default     = []
}

variable "default_action" {
  type        = string
  description = "The action to perform if none of the rules contained in the WebACL match."
  default     = "allow"
  validation {
    condition     = can(regex("^(allow|block)$", var.default_action))
    error_message = "Default action must be one of: allow, block"
  }
}

variable "associate_resource_arn" {
  type        = string
  description = <<EOF
    The ARN of the resource to associate with the web ACL.

    From the aws_wafv2_web_acl_association documentation:
    This must be an ARN of an Application Load Balancer, an Amazon API Gateway stage (REST only,
    HTTP is unsupported), an Amazon Cognito User Pool, an Amazon AppSync GraphQL API,
    an Amazon App Runner service, or an Amazon Verified Access instance.

    Note: the README contains a list of IAM permissions, this ARN needs to be added to the statement
    with the Sid `AssociateWAF` else the association will fail.
  EOF
  validation {
    condition     = can(regex("arn:aws.*", var.associate_resource_arn))
    error_message = "The ARN must be a valid AWS ARN."
  }
}