# Sets the allowable actions to be used inside the repo
resource "github_actions_repository_permissions" "managed_repository" {
  for_each        = local.repo_definitions
  repository      = each.key
  enabled         = each.value.actions.enabled
  allowed_actions = each.value.actions.allowed_actions

  dynamic "allowed_actions_config" {
    # Only create this section if the allowed_actions is set to selected, else it'll fail.
    for_each = each.value.actions.allowed_actions == "selected" ? [1] : []
    content {
      github_owned_allowed = each.value.actions.allowed_select_github_owned
      verified_allowed     = each.value.actions.allowed_select_verified
      patterns_allowed     = each.value.actions.allowed_select_patterns
    }
  }
}

# Sets whether or not actions can be shared from this repo to others
resource "github_actions_repository_access_level" "managed_repository" {
  for_each     = local.repo_definitions
  repository   = each.key
  access_level = each.value.actions.resuable_actions_scope

  depends_on = [
    github_repository.managed_repository
  ]
}