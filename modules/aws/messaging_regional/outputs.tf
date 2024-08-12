output "cmk_alias" {
  value       = aws_kms_alias.messaging.id
  description = "The alias to the messaging key."
}

output "cmk_arn" {
  value       = aws_kms_key.messaging.arn
  description = "The ARN of the KMS customer managed messaging key."
}
