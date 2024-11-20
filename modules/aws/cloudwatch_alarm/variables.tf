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

variable "severity" {
  description = <<EOF
    Set the severity of the alarm. The severity will be appended to the alarm name, and the alarm
    will be tagged with the severity. Values are, with typical response times described:
    * SEV1 - System is down or critical business impact, requires immediate attention.
    * SEV2 - System is degraded or has a moderate business impact, requires same-day attention.
    * SEV3 - System is experiencing minor issues or has a low business impact, requires attention within 3 days.
  EOF
  type        = string
  validation {
    condition     = can(regex("^(SEV1|SEV2|SEV3)$", var.severity))
    error_message = "Severity must be one of SEV1 (High), SEV2 (Medium), or SEV3 (Low)."
  }
}

variable "runbook" {
  description = <<EOF
    URL for the runbook outlining actions to take when the alarm triggers. This is required,
    and it will be included in the alert message sent to Slack/Teams/Email.
  EOF
  type        = string
  validation {
    condition     = can(regex("https?://.*", var.runbook))
    error_message = "Runbook must be a valid URL."
  }
  validation {
    condition     = length(var.runbook) < 256
    error_message = "Runbook URL must be less than 256 characters."
  }
}

variable "description" {
  description = <<EOF
    Description of the alarm, will be displayed in the CloudWatch dashboard as well as the alerts in
    Slack/Teams/Email.

    CloudWatch supports a subset of Markdown, see the AWS Console for details. The runbook
    link will be appended to the end of the description.
  EOF
  type        = string
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate the metric for."
  type        = number
  default     = 1
}

variable "comparison_operator" {
  description = <<EOF
    Comparison operator to use for the alarm. The following are supported:
    GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, or LessThanOrEqualToThreshold.
  EOF
  type        = string
  default     = "GreaterThanOrEqualToThreshold"
  validation {
    condition     = can(regex("^(GreaterThanOrEqualToThreshold|GreaterThanThreshold|LessThanThreshold|LessThanOrEqualToThreshold)", var.comparison_operator))
    error_message = "Comparison operator must be one of GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold."
  }
}

variable "treat_missing_data" {
  description = <<EOF
    Sets how this alarm is to handle missing data points. The following values are supported:
    missing, ignore, breaching and notBreaching. Defaults to notBreaching.
  EOF
  type        = string
  default     = "notBreaching"
  validation {
    condition     = can(regex("^(missing|ignore|breaching|notBreaching)$", var.treat_missing_data))
    error_message = "treat_missing_data must be one of missing, ignore, breaching, or notBreaching."
  }
}

variable "dimensions" {
  description = <<EOF
    Dimensions to filter the metric by. See
    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html for more details.
  EOF
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = <<EOF
    Namespace for the metric. See
    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html for more details.
  EOF
  type        = string
}

variable "metric_name" {
  description = <<EOF
    Name of the metric. See
    https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html for more details.
  EOF
  type        = string
}

variable "period" {
  description = "Period in seconds over which the specified statistic is applied."
  type        = number
  default     = 300
  validation {
    condition     = var.period == 10 || var.period == 30 || var.period % 60 == 0
    error_message = "Period must be a multiple of 10, 30, or a multiple 60 seconds."
  }
}

variable "threshold" {
  description = "Threshold for the alarm. Ignored if using anomaly detection."
  type        = number
  default     = 1
}

variable "statistic" {
  description = "Statistic to use for the alarm."
  type        = string
  default     = "Sum"
  validation {
    condition     = can(regex("^(SampleCount|Average|Sum|Minimum|Maximum)$", var.statistic))
    error_message = "Statistic must be one of SampleCount, Average, Sum, Minimum, or Maximum."
  }
}


