variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "description" {
  type = string
}
variable "severity" {
  type = string
}

variable "runbook" {
  type = string
}

variable "evaluation_periods" {
  type = number
}

variable "comparison_operator" {
  type = string
}

variable "dimensions" {
  type = map(string)
}

variable "namespace" {
  type = string
}

variable "metric_name" {
  type = string
}

variable "period" {
  type = number
}

variable "use_anomaly_detection" {
  type = bool
}

variable "threshold" {
  type = number
}

variable "statistic" {
  type = string
}