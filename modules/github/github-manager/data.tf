data "github_organization" "root" {
  name         = var.github_owner
  summary_only = true
}
