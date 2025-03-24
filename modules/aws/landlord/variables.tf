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

variable "app_url" {
  description = "The base URL of the app with its protocol scheme, used by Landlord & Cognito to redirect to after login"
  type        = string
  validation {
    condition     = can(regex("^https?:\\/\\/[a-zA-Z0-9.-]+(:[0-9]{1,5})?$", var.app_url))
    error_message = "The app URL must include the scheme and domain, but no path information. Do not include a trailing slash."
  }
}

variable "app_name" {
  description = "The name of the app using landlord. Used in various UI displays when authenticating"
  type        = string
}

variable "app_admin_email" {
  description = "The email address of an app administrator, used when sending alert notifications"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.app_admin_email))
    error_message = "The app admin email must be a valid email address."
  }
}

variable "sms_aws_region" {
  description = <<EOF
  The AWS region where SMS is configured (via SNS). If this is left blank, the current region where
  the stack is deployed will be used. See
  https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-sms-settings.html
  on how to setup SMS for Cognito.
  EOF
  type        = string
}

variable "hosted_ui_css_filename" {
  description = <<EOF
  Custom CSS to be applied to the hosted UI (classic) for branding, provided as a file path to the CSS file.
  If not provided, the default AWS branding will be used. See
  https://docs.aws.amazon.com/cognito/latest/developerguide/hosted-ui-classic-branding.html
  for details.
  EOF
  type        = string
  default     = ""
}

variable "hosted_ui_logo_filename" {
  description = <<-EOF
    The uploaded logo image for the UI customization, provided as  file path to the image file.
    Drift detection is not possible for this argument. If not provided, the default AWS branding will be used. See
    https://docs.aws.amazon.com/cognito/latest/developerguide/hosted-ui-classic-branding.html
    for details.
  EOF
  type        = string
  default     = ""
}

variable "invite_email_template_filename" {
  description = <<-EOF
    Filename for the invite Email template. If not provided, a simple one line message
    will appear in the invite email.
  EOF
  type        = string
  default     = ""
}

variable "custom_domain_prefix" {
  description = <<EOF
    The custom domain prefix for the Cognito Hosted UI. Note this must be globally unique to all customers and
    regions, so pick a unique one. The resulting domain will be
    {var.custom_domain_prefix}.auth.{current region}.amazoncognito.com.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[a-z[a-z0-9-]+$", var.custom_domain_prefix))
    error_message = "The custom domain prefix must be lower case alphanumeric, can contain hyphens, and has leading letter."
  }
}

variable "hosted_zone_name" {
  description = <<EOF
  The name of the hosted zone in Route53 in which to create the Route53 entries for the load balancers. This
  will also be used to create the certificate names. Two names will be created:
  * {var.name}.{var.hosted_zone_name}
  * {var.name}-api.{var.hosted_zone_name}
  For example, if var.name is set to "landlord" and var.hosted_zone_name is set to "example.com", the following
  certificates and Route53 entries will be created:
  * landlord.example.com
  * landlord-api.example.com
  EOF
  type        = string
}

variable "cognito_callback_urls" {
  description = <<EOF
  List of callback URLs that are allowed as destinations after Cognito authentication.
  EOF
  type        = list(string)
  default     = []
}

variable "vpc_environment_tag" {
  description = <<EOF
    The `environment` tag used to look up the VPC and resources in it. Typically there's one VPC
    per account, with an environment like 'Dev', 'Test', or 'Prod' but there is a possibility of more
    if it was configured that way.
  EOF
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.vpc_environment_tag))
    error_message = "VPC Environment Tag must be alphanumeric and capitalized."
  }
}

variable "cognito_email_sending_account" {
  # Cognito uses the value "DEVELOPER" to indicate that the email sending account is the developer's
  # own account. This is used for production environments.
  description = "One of 'COGNITO_DEFAULT' for dev/test usages or 'DEVELOPER' for prod usages"
  type        = string
  default     = "COGNITO_DEFAULT"
  validation {
    condition     = contains(["COGNITO_DEFAULT", "DEVELOPER"], var.cognito_email_sending_account)
    error_message = "Must be one of COGNITO_DEFAULT or DEVELOPER"
  }
}

# In the AWS console this is called: "FROM sender name"
#
# AWS says:
#    FROM sender name - optional
#    Enter a friendly name for the email sender in the format "John Stiles <johnstiles@example.com>.“
variable "cognito_from_email_address" {
  description = "The email address that emails will be sent from"
  type        = string
  default     = ""
  validation {
    condition     = var.cognito_from_email_address == "" || can(regex("^[a-zA-Z0-9\\s]+(\\s[a-zA-Z0-9\\s]+)*\\s<[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}>$", var.cognito_from_email_address))
    error_message = "The email_from value must be in the format 'Name <email@domain.com>'."
  }
}

# This, as compared to "cognito_from_email_address", is just an email address
variable "cognito_reply_to_email_address" {
  description = "The email address that emails will be replied to"
  type        = string
  default     = ""
  validation {
    condition     = var.cognito_reply_to_email_address == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.cognito_reply_to_email_address))
    error_message = "The reply to email address must be a valid email address."
  }
}

variable "cognito_ses_source_arn" {
  description = "The ARN of the SES identity that Cognito will use to send emails"
  type        = string
  default     = ""
}

variable "user_profile_fields" {
  description = "List of profile field definitions for users"
  type = list(object({
    name                    = string
    ui_name                 = string
    format                  = string
    max_len                 = number
    min_len                 = number
    prevent_empty           = optional(bool, false)
    regex_validator         = optional(string, "")
    invite_time_field       = optional(bool, false)
    possible_values_url     = optional(string, "")
    possible_values_jq_expr = optional(string, "")
  }))
  default = []
}

variable "tenant_profile_fields" {
  description = "List of profile field definitions for tenants"
  type = list(object({
    name                    = string
    ui_name                 = string
    format                  = string
    max_len                 = number
    min_len                 = number
    prevent_empty           = optional(bool, false)
    regex_validator         = optional(string, "")
    invite_time_field       = optional(bool, false)
    possible_values_url     = optional(string, "")
    possible_values_jq_expr = optional(string, "")
  }))
  default = []
}
