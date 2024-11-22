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

variable "lambda_arn" {
  description = <<EOF
    ARN of the Lambda function to be scheduled. If using the Apres Lambda module, this will be the output
    variable `lambda_function_arn`.
  EOF
  type        = string
  validation {
    condition     = can(regex("^arn:aws:lambda:[a-z]{2}-[a-z]+-[0-9]:[0-9]{12}:function:[a-zA-Z0-9-_]+$", var.lambda_arn))
    error_message = "Lambda ARN must be in the format arn:aws:lambda:<region>:<account-id>:function:<function-name>"
  }
}

variable "lambda_function_name" {
  description = <<EOF
    Name of the Lambda function to be scheduled. If using the Apres Lambda module, this will be the output
    variable `lambda_function_name`.
  EOF
  type        = string
}

variable "schedule_expression" {
  description = <<EOF
    Schedule expression for the Lambda function. using cron or rate syntax. See
    [Using cron and rate](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html)
    documentation for details on the format.
  EOF
  type        = string
  validation {
    condition     = can(regex("^(rate|cron)", var.schedule_expression))
    error_message = "Schedule expression must begin with cron or rate."
  }
}