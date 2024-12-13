variable "environment" {
  description = "Environment name, used for tagging AWS resources."
  type        = string
  default     = "Dev"
}

variable "name" {
  description = "Name of the ECR repo"
  type        = string
  validation {
    condition     = length(var.name) >= 2 && length(var.name) < 256
    error_message = "Name length must be between 5 and 255 characters."
  }
  validation {
    condition     = can(regex("^[a-z][a-z0-9-_/]*$", var.name))
    error_message = "The name must start with a letter and can only contain lowercase letters, numbers, hyphens, underscores, periods and forward slashes."
  }
}

variable "shared_aws_org_for_pull" {
  description = <<EOL
  Path to an AWS Organizations OU to share the repo to. This is translated to a condition using the
  aws:PrincipalOrgPaths condition key. See https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-principalorgpaths for more information.
  A valid example might "org-id/root-ou-id/*" (Remember to use the Org ID as the root!)
  EOL
  type        = list(string)
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
}

variable "application" {
  description = "Application name, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.application))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "component" {
  description = "Component name, used for tagging AWS resources."
  type        = string
  default     = "ECR"
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.component))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "owner" {
  description = "Owner of the resources, used for tagging AWS resources."
  type        = string
  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9]*$", var.owner))
    error_message = "Application name must be alphanumeric and capitalized."
  }
}

variable "extra_tags" {
  description = "Extra tags to be applied to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for x in var.extra_tags : can(regex("^[A-Z][a-zA-Z0-9]+$", x))])
    error_message = "Tag values must be alphanumeric and capitalized."
  }
}

variable "primary_region" {
  description = <<EOF
    The module creates IAM resources, which can only be created in one region. If you are creating
    the same repository in multiple regions, use this variable to specify the primary region which
    is responsible for creating the IAM resources. Leaving it blank means the current region will
    be used.
  EOF
  type        = string
  default     = ""
}