variable "github_owner" {
  type        = string
  description = <<EOF
  This is the target GitHub organization or individual user account to manage. For example, 'apresdev'.

  A hint in finding the owner is to look at the URL of the organization. For example, the URL
  for the apresdev organization is https://github.com/apresdev/ and the github_owner is `apresdev`.
  EOF
}

variable "repo_directory" {
  type        = string
  description = <<EOF
    Directory where the repository yaml files exist, relative to where the module lives. For example,
    if the module is called from `terraform/github-manager`, and the repository yaml files are in
    `config/repos`, then the value of this variable should be `$${path.module}/../../config/repos`
  EOF
}

variable "team_directory" {
  type        = string
  description = <<EOF
    Directory where the team yaml files exist, relative to where the module lives. For example,
    if the module is called from `terraform/github-manager`, and the team yaml files are in
    `config/teams`, then the value of this variable should be `$${path.module}/../../config/teams`
  EOF
}

variable "member_directory" {
  type        = string
  description = <<EOF
    Directory where the member yaml files exist, relative to where the module lives. For example,
    if the module is called from `terraform/github-manager`, and the member yaml files are in
    `config/repos`, then the value of this variable should be `$${path.module}/../../config/member`
  EOF
}
