output "waf_arn" {
  description = "The ARN of the WAF ACL"
  value       = module.waf.waf_arn
}