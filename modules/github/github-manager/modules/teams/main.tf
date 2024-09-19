resource "github_team" "default" {
  name        = var.name
  description = var.description
  privacy     = var.privacy
}