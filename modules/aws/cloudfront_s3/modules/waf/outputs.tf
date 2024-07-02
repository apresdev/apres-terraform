output "waf_arn" {
  value       = aws_wafv2_web_acl.default.arn
  description = "ARN of the WAF (web acl v2)"
}