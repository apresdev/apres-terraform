output "iam_role_arn" {
  description = "The ARN of the IAM role for the bastion host(s)."
  value       = module.bastion.iam_role_arn
}

output "security_group_id" {
  description = "The ID of the security group for the bastion host(s)."
  value       = module.bastion.security_group_id
}

output "instance_ids" {
  description = "A list of the IDs of the bastion host(s)."
  value       = module.bastion.instance_ids
}
