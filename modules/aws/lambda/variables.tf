# #########################################################################################################################################
# Required Variables
# #########################################################################################################################################
variable "name" {
  description = <<EOF
  The name of the lambda function.  Used to name all dependent resources required by the function (e.g. DLQ, signing jobs, etc.)
  EOF
  type        = string
  nullable    = false
}

variable "binary_path" {
  description = <<EOF
  This path to the lambda executable file.
  EOF
  type        = string
  nullable    = false
}

variable "runtime" {
  description = <<EOF
  Identifier of the function's runtime.
  EOF
  type        = string
  nullable    = false
}

# #########################################################################################################################################
# Optional Variables
# #########################################################################################################################################
variable "memory_size" {
  description = <<EOF
  (Optional) Amount of memory in MB your Lambda Function can use at runtime. 
  Defaults to 128.
  EOF
  type        = number
  default     = 128
}

variable "handler" {
  description = <<EOF
  (Optional) Function entrypoint in your code.
  EOF
  type        = string
  nullable    = true
  default     = null
}

variable "timeout" {
  description = <<EOF
  (Optional) Amount of time your Lambda Function has to run in seconds. 
  Defaults to 3 seconds. 
  EOF
  type        = number
  default     = 128
}


variable "architectures" {
  description = <<EOF
  (Optional) Instruction set architecture for your Lambda function. 
  Valid values are ["x86_64"] and ["arm64"]. 
  Default is ["arm64"]. 
  Removing this attribute, function's architecture stay the same.
  EOF
  type        = list(string)
  default     = ["arm64"]
  validation {
    condition     = var.architectures == null || alltrue([for architecture in var.architectures : contains(["x86_64", "arm64"], architecture)])
    error_message = "architectures must be either x86_64 or arm64, if specified"
  }
}

variable "environment_variables" {
  description = <<EOF
  (Optional) Map of environment variables that are accessible from the function code during execution. 
  If provided at least one key must be present.
  EOF
  type        = map(string)
  nullable    = true
  default     = null
  validation {
    condition     = length(var.environment_variables != null ? var.environment_variables : { "one" : "value" }) > 0
    error_message = "environment_variables must have at least one variable, if specified"
  }
}

variable "description" {
  description = <<EOF
  (Optional) Description of what your Lambda Function does.
  EOF
  type        = string
  default     = ""
}

variable "ephemeral_storage" {
  description = <<EOF
  (Optional) The amount of Ephemeral storage(/tmp) to allocate for the Lambda Function in MB. 
  This parameter is used to expand the total amount of Ephemeral storage available, beyond the default amount of 512MB.
  EOF
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage == null || var.ephemeral_storage >= 512
    error_message = "ephemeral_storage must be at least 512MB, if specified"
  }

  validation {
    condition     = var.ephemeral_storage == null || var.ephemeral_storage <= 10240
    error_message = "ephemeral_storage must be at most 10,240MB, if specified"
  }
}

variable "reserved_concurrent_executions" {
  description = <<EOF
  (Optional) Amount of reserved concurrent executions for this lambda function. 
  A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. 
  Defaults to Unreserved Concurrency Limits -1.
  EOF
  type        = number
  default     = -1
}

# #########################################################################################################################################
# Regional variables
# #########################################################################################################################################
variable "vpc" {
  description = <<EOF
    Controls the lambda's VPC settings.
    The enabled field controls whether the lambda runs in the private subnets of the VPC.  Defaults to false.
    The environment_tag is used to lookup the VPC based on the VPCs tag structure.  Required if enabled is true.
  EOF
  type = object({
    enabled         = bool
    environment_tag = string
  })

  default = {
    enabled         = false
    environment_tag = null
  }

  validation {
    condition     = !var.vpc.enabled || var.vpc.environment_tag != null
    error_message = "vpc.environment_tag is required if vpc.enabled is true."
  }

  validation {
    condition     = var.vpc.enabled || var.vpc.environment_tag == null || can(regex("^[A-Z][a-zA-Z0-9]*$", var.vpc.environment_tag))
    error_message = "vpc.environment_tag must be alphanumeric and capitalized if specified."
  }
}

# #########################################################################################################################################
# Regional Lambda variables
# #########################################################################################################################################
variable "lambda_regional_environment" {
  description = "Lambda Regional Environment Name, used to lookup regional code signing and S3 buckets."
  type        = string
  default     = "WorkLoadConfig"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.lambda_regional_environment))
    error_message = "Environment name must be alphanumeric and capitalized."
  }
}


# BEGIN_COMMON_VARS
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
  default     = "CloudWatchLogs"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  default     = "CloudWatchLogs"
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
# END_COMMON_VAR
