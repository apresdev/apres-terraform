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
  value       = aws_iam_role.github_actions.arn
}

output "github_iam_role_name" {
  description = "GitHub OIDC IAM Role Name"
  value       = aws_iam_role.github_actions.name
}

output "github_iam_policy_arn" {
  description = "GitHub OIDC IAM Policy ARN"
  value       = aws_iam_policy.github_actions.arn
}