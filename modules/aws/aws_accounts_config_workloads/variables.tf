variable "enable_api_gateway_logging" {
  description = <<EOF
    Enable API Gateway logging to CloudWatch Logs. This requires an IAM Role and an API Gateway
    configuration per region. By default this is disabled, enable if you are planning to
    use API Gateway in the account this is deployed in.
  EOF
  type        = bool
  default     = false
}