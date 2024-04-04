output "repository_arn" {
  description = "Repository ARN"
  value       = module.ecr_repo.repository_arn
}

output "repository_url" {
  description = "Repository URL"
  value       = module.ecr_repo.repository_url
}

output "github_iam_role_arn" {
  description = "GitHub OIDC IAM Role ARN"
  value       = module.ecr_repo.github_iam_role_arn
}

output "github_iam_role_name" {
  description = "GitHub OIDC IAM Role Name"
  value       = module.ecr_repo.github_iam_role_name
}