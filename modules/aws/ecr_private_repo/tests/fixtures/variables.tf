variable "name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "example-repo"
}

variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "Example"
}

variable "shared_aws_org_for_pull" {
  description = <<EOL
    Path to an AWS Organizations OU to share the repo to. This is translated to a condition using the
    aws:PrincipalOrgPaths condition key. See https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-principalorgpaths for more information.
    A valid example might "org-id/root-ou-id/*" (Remember to use the Org ID as the root!)
    EOL
  type        = list(string)
  default     = ["o-a1b2c3d4e5/r-ab12/*"]
}

variable "github_repo_subject_claim_filter" {
  description = <<EOF
    The GitHub repo to trust for GitHub Actions. Also known as the Subject claim filter for
    valid tokens. Must be in the format of
    repo:apresdev/repo-name:ref:refs/heads/branch-or-tag, can be a comma delimited
    list if there is more than one. Example:
    * repo:apresdev/iac:ref:refs/heads/main means only the main branch of the apresdev/iac repo can assume the role.
    * repo:apresdev/iac:* means any branch or tag of the apresdev/iac repo can assume the role.
    See https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    for examples of filtering by branch or deployment environment.
    EOF
  type        = string
  default     = "repo:apresdev/apres-terraform:ref:refs/heads/main"
}