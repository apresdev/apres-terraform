output "waf_arn" {
  description = "The ARN of the WAF ACL"
  value       = aws_wafv2_web_acl.default.arn
}