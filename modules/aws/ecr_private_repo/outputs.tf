output "repository_arn" {
  description = "Repository ARN"
  value       = aws_ecr_repository.repo.arn
}

output "repository_url" {
  description = "Repository URL"
  value       = aws_ecr_repository.repo.repository_url
}

output "github_iam_role_arn" {
  description = "GitHub OIDC IAM Role ARN"
  value       = local.create_iam_artifacts ? aws_iam_role.github_actions[0].arn : null
}

output "github_iam_role_name" {
  description = "GitHub OIDC IAM Role Name"
  value       = local.create_iam_artifacts ? aws_iam_role.github_actions[0].name : null
}

output "github_iam_policy_arn" {
  description = "GitHub OIDC IAM Policy ARN"
  value       = local.create_iam_artifacts ? aws_iam_policy.github_actions[0].arn : null
}