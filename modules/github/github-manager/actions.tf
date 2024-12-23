# Sets the allowable actions to be used inside the repo
resource "github_actions_repository_permissions" "managed_repository" {
  for_each        = local.repo_definitions
  repository      = each.key
  enabled         = try(each.value.actions.enabled, local.defaults.actions.enabled)
  allowed_actions = try(each.value.actions.allowed_actions, local.defaults.actions.allowed_actions)

  dynamic "allowed_actions_config" {
    # Only create this section if the allowed_actions is set to selected, else it'll fail.
    for_each = try(each.value.actions.allowed_actions == "selected" ? [1] : [], [])
    content {
      github_owned_allowed = try(each.value.actions.allowed_select_github_owned, local.defaults.actions.allowed_select_github_owned)
      verified_allowed     = try(each.value.actions.allowed_select_verified, local.defaults.actions.allowed_select_verified)
      patterns_allowed     = try(each.value.actions.allowed_select_patterns, local.dedicated_actions.allowed_select_patterns)
    }
  }

  depends_on = [
    github_repository.managed_repository
  ]
}

# Sets whether or not actions can be shared from this repo to others
resource "github_actions_repository_access_level" "managed_repository" {
  for_each     = local.repo_definitions
  repository   = each.key
  access_level = try(each.value.actions.reusable_actions_scope, local.defaults.actions.reusable_actions_scope)

  depends_on = [
    github_repository.managed_repository
  ]
}