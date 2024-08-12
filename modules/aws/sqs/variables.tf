variable "environment" {
  description = "Environment name, used for tagging AWS resources, and in the bucket name."
  type        = string
  default     = "dev"
  nullable    = false
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Component name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Owner must be alphanumeric and capitalized."
  }
}

variable "default_tags" {
  description = "Default set of tags to be applied to all resources"
  type        = map(string)
  default     = {}
  nullable    = false
}

# From: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-queues.html
# A queue name can have up to 80 characters.
# The following characters are accepted: alphanumeric characters, hyphens (-), and underscores (_).
#
# The overhead of our standard naming convention is approximately 40 characters (which includes the account id, the region, the 
# environment, and the optional deadletter suffix), so we will restrict the user supplied input to 40 characters to attempt to avoid 
# overloading the full SQS queue name limitations.
variable "name" {
  description = "Name of the queue, must be between 3 and 40 characters long and can contain only the following characters: a-z, A-Z, 0-9, _, and -"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.name) >= 3 && length(var.name) < 40
    error_message = "Name length must be between 3 and 40 characters."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-]*$", var.name))
    error_message = "The name only contain letters, numbers, underscores, hyphens, and dots."
  }
}

variable "visibility_timeout_seconds" {
  description = <<EOF
  (Optional) The visibility timeout for the queue. An integer from 0 to 43200 (12 hours). The default for this attribute is 30. For more information about visibility timeout, see AWS docs.
  EOF
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = <<EOF
  (Optional) The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). The default for this attribute is 1209600 (14 days).
  EOF
  type        = number
  default     = 1209600
}

variable "max_message_size" {
  description = <<EOF
  (Optional) The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB). The default for this attribute is 262144 (256 KiB).
  EOF
  type        = number
  default     = 262144
}

variable "delay_seconds" {
  description = <<EOF
  (Optional) The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes). The default for this attribute is 0 seconds." 
  EOF
  type        = number
  default     = 0
}

variable "encryption_kms_key_id" {
  description = <<EOF
  The ARN of the KMS key to use for server-side encryption. 
  If not provided, the default customer managed key 'alias/apres/messaging' will be used.
  EOF
  type        = string
  nullable    = false
  default     = "alias/apres/messaging"
}

variable "policy" {
  description = <<EOF
  (Optional) The JSON policy for the SQS queue.
  EOF
  type        = string
  default     = ""
}

variable "historical_latency_alarms" {
  type = list(object({
    severity            = number
    datapoints_to_alarm = number
    evaluation_periods  = number
    period              = number
    threshold           = number
  }))

  validation {
    condition = alltrue([
      for alarm in var.historical_latency_alarms : alarm.threshold > 0
    ])
    error_message = "threshold must all be greater than zero"
  }

  validation {
    condition = alltrue([
      for alarm in var.historical_latency_alarms : alarm.severity >= 1 && alarm.severity <= 5
    ])
    error_message = "severity must be between 1 and 5"
  }

  validation {
    condition = alltrue([
      for alarm in var.historical_latency_alarms : alarm.datapoints_to_alarm > 0
    ])
    error_message = "datapoints_to_alarm must be positive"
  }

  validation {
    condition = alltrue([
      for alarm in var.historical_latency_alarms : alarm.evaluation_periods > 0
    ])
    error_message = "evaluation_periods must be positive"
  }

  validation {
    condition = alltrue([
      for alarm in var.historical_latency_alarms : alarm.period > 0
    ])
    error_message = "period must be positive"
  }

  # For the default, we will generate a SEV-2 alarm to indicate that the latency has violated the SLO threshold for the last fifteen minutes.
  default = [{
    severity            = 2
    datapoints_to_alarm = 15,
    evaluation_periods  = 15
    period              = 60
    threshold           = 1800
  }]

  nullable = false

}

variable "projected_latency_alarms" {
  type = list(object({
    severity            = number
    datapoints_to_alarm = number
    evaluation_periods  = number
    period              = number
    threshold           = number
  }))

  validation {
    condition = alltrue([
      for alarm in var.projected_latency_alarms : alarm.threshold > 0
    ])
    error_message = "threshold must all be greater than zero"
  }

  validation {
    condition = alltrue([
      for alarm in var.projected_latency_alarms : alarm.severity >= 1 && alarm.severity <= 5
    ])
    error_message = "severity must be between 1 and 5"
  }

  validation {
    condition = alltrue([
      for alarm in var.projected_latency_alarms : alarm.datapoints_to_alarm > 0
    ])
    error_message = "datapoints_to_alarm must be positive"
  }

  validation {
    condition = alltrue([
      for alarm in var.projected_latency_alarms : alarm.evaluation_periods > 0
    ])
    error_message = "evaluation_periods must be positive"
  }

  validation {
    condition = alltrue([
      for alarm in var.projected_latency_alarms : alarm.period > 0
    ])
    error_message = "period must be positive"
  }

  # For the default, we will generate a SEV-3 alarm to indicate that the latency will violate the the SLO threshold within the next five minutes.
  default = [{
    severity            = 3
    datapoints_to_alarm = 10,
    evaluation_periods  = 10
    period              = 60
    threshold           = 1800
  }]

  nullable = false

}

variable "error_rate_alarms" {
  type = list(object({
    severity            = number
    datapoints_to_alarm = number
    evaluation_periods  = number
    period              = number
    threshold           = number
  }))

  validation {
    condition = alltrue([
      for alarm in var.error_rate_alarms : alarm.threshold > 0
    ])
    error_message = "threshold must all be greater than zero"
  }

  validation {
    condition = alltrue([
      for alarm in var.error_rate_alarms : alarm.severity >= 1 && alarm.severity <= 5
    ])
    error_message = "severity must be between 1 and 5"
  }

  validation {
    condition = alltrue([
      for alarm in var.error_rate_alarms : alarm.datapoints_to_alarm > 0
    ])
    error_message = "datapoints_to_alarm must be positive"
  }

  validation {
    condition = alltrue([
      for alarm in var.error_rate_alarms : alarm.evaluation_periods > 0
    ])
    error_message = "evaluation_periods must be positive"
  }

  validation {
    condition = alltrue([
      for alarm in var.error_rate_alarms : alarm.period > 0
    ])
    error_message = "period must be positive"
  }

  # By default, we will generate a SEV-3 alarm to indicate that error rate has exceeded 10% for the last fifteen minutes
  default = [{
    severity            = 3
    datapoints_to_alarm = 15,
    evaluation_periods  = 15
    period              = 60
    threshold           = 10
  }]

  nullable = false

}

