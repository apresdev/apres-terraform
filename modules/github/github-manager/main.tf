# Creates the repository from the repository definition YAML.  The default values are defined in the repo.schema.yaml schema file and are
# pre-loaded in the local.defaults.
resource "github_repository" "managed_repository" {
  for_each             = local.repo_definitions
  name                 = each.key
  description          = replace(trimspace(each.value.description), "/[\r\n]/", "")
  auto_init            = true
  vulnerability_alerts = true

  security_and_analysis {

  }

  # Repos should be private by default, you should have to explicitly specify it as public
  visibility = try(each.value.visibility, local.defaults.visibility) == "public" ? "public" : "private"

  # Default Pull Request Permissions, allow merge commit and squash merges, but not rebase merge (we do not want to flood the main branch
  # with interim commits from feature branches)
  allow_merge_commit     = true == try(each.value.pullRequests.allowMergeCommit, local.defaults.pullRequests.allowMergeCommit)
  allow_squash_merge     = true == try(each.value.pullRequests.allowSquashMerge, local.defaults.pullRequests.allowSquashMerge)
  allow_rebase_merge     = true == try(each.value.pullRequests.allowRebaseMerge, local.defaults.pullRequests.allowRebaseMerge)
  delete_branch_on_merge = true == try(each.value.pullRequests.deleteBranchOnMerge, local.defaults.pullRequests.deleteBranchOnMerge)

  allow_auto_merge = (try(each.value.visibility, local.defaults.visibility) == "public" || local.features.branchProtection) && true == try(
    each.value.pullRequests.allowAutoMerge, local.defaults.pullRequests.allowAutoMerge
  )

  has_issues      = true == try(each.value.features.hasIssues, local.defaults.features.hasIssues)
  has_projects    = true == try(each.value.features.hasProjects, local.defaults.features.hasProjects)
  has_discussions = true == try(each.value.features.hasDiscussions, local.defaults.features.hasDiscussions)
  has_downloads   = true == try(each.value.features.hasDownloads, local.defaults.features.hasDownloads)

  is_template = true == try(each.value.isTemplate, local.defaults.isTemplate)

  topics = try(each.value.topics, local.defaults.topics)
}

# Enable dependabot security updates
resource "github_repository_dependabot_security_updates" "managed_repository" {
  for_each   = local.repo_definitions
  repository = each.key
  enabled    = true

  depends_on = [
    github_repository.managed_repository
  ]
}

#
# Create the branch protections for the repo.
#
# We apply branch protections to the default branch (usually main) to ensure that users cannot inject code without a reviewed and approved
# pull request.
#
# - [x] Prevent force pushes and deletions
# - [x] Require a pull request before merging
#   - [x] Define a minimal number of required approvals before merging
#   - [x] Dismiss stale pull request approvals when new commits are pushed
#   - [x] Require review from Code Owners (defined in a dedicated file inside the repository)
#   - [x] Restrict who can dismiss pull request reviews
# - [x] Require a branch to be up to date and pass predefined status checks before merging
# - [x] Require conversation resolution before merging
# - [x] Require signed commits
# - [] Require deployments to succeed before merging
# - [x] Enforce restrictions for administrators as well
#
# References:
# - https://www.legitsecurity.com/blog/github-security-best-practices-your-team-should-be-following
#
resource "github_branch_protection" "default" {
  #checkov:skip=CKV_GIT_5: Only want 1 approval for PR's, checkov wants 2.
  for_each = local.protected_repo_definitions

  repository_id = github_repository.managed_repository[each.key].name
  pattern       = try(each.value.defaultBranch, local.defaults.defaultBranch)
  # Lock the branch if the repo is flagged as read-only.
  lock_branch = try(each.value.readOnly, false) == true

  # - Prevent force pushes and deletions
  allows_deletions    = false
  allows_force_pushes = false

  # - Require a pull request before merging
  #   - Define a minimal number of required approvals before merging
  #   - Dismiss stale pull request approvals when new commits are pushed
  #   - Require review from Code Owners (defined in a dedicated file inside the repository)
  #   - Restrict who can dismiss pull request reviews
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    dismissal_restrictions          = []
    require_last_push_approval      = true

  }

  # - Require a branch to be up to date and pass predefined status checks before merging
  required_status_checks {
    strict   = true
    contexts = try(each.value.requiredStatusChecks, [])
  }

  # - Require conversation resolution before merging
  require_conversation_resolution = true

  # - Require signed commits
  require_signed_commits = true

  # - [] Require deployments to succeed before merging
  # TODO: Look into managing deployments

  # - Enforce restrictions for administrators as well
  enforce_admins = true

  required_linear_history = true

  depends_on = [
    github_repository.managed_repository
  ]

}

# NOTE: If we create an github_issue_labels resource, it _should_ wipe out the default
# labels that are created by GitHub. The alternative is to use the github_issue_label
# but then we can only add, never remove.
resource "github_issue_labels" "default" {
  for_each = {
    for k, v in local.repo_definitions : k => v if contains(keys(local.repo_definitions[k]), "labels")
  }
  repository = each.key

  dynamic "label" {
    for_each = each.value.labels
    content {
      name        = label.value.name
      color       = label.value.color
      description = contains(keys(label.value), "description") ? label.value.description : ""
    }
  }

  depends_on = [
    github_repository.managed_repository
  ]
}


# Add the team members to the repo
resource "github_team_repository" "default" {
  count      = length(local.repo_teams_assignments)
  team_id    = module.teams[local.repo_teams_assignments[count.index].team].id
  repository = local.repo_teams_assignments[count.index].repo
  permission = local.repo_teams_assignments[count.index].permission
}