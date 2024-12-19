output "iam_role_arn" {
  description = "The ARN of the IAM role for the bastion host(s)."
  value       = aws_iam_instance_profile.default.arn
}

output "security_group_id" {
  description = "The ID of the security group for the bastion host(s)."
  value       = aws_security_group.default.id
}

output "instance_ids" {
  description = "A list of the IDs of the bastion host(s)."
  value       = aws_instance.default[*].id
}
