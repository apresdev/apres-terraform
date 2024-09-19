locals {
  repo_definitions = {
    for fn in fileset(var.repo_directory, "*.yaml") :
    # Convert to kebab-case as per recommended naming conventions
    lower(
      replace(
        substr(fn, 0, length(fn) - 5),
        "/[ ._]/",
        "-"
      )
    ) =>
    yamldecode(
      file("${var.repo_directory}/${fn}")
    )
  }

  # Create a filtered list of repos that includes a repo_definitions if and only if the repo is "public" (available to all plans OR the
  # branchProtection feature is available in the GitHub organization's plan.  This allows us to conditionally render resources in a
  # for_each loop.
  protected_repo_definitions = {
    for k, v in local.repo_definitions : k => v
    if try(v.visibility, local.defaults.visibility) == "public" || local.features.branchProtection
  }

  # Create a flattened list of repos and teams and permissions, for example:
  # [
  #   {
  #     repo = "repo1"
  #     team = "team1"
  #     permission = "pull"
  #   }
  # ]
  repo_teams_assignments = flatten([
    for repo, repo_definition in local.repo_definitions : [
      for team in try(repo_definition.teams, []) : {
        repo       = repo
        team       = team.name
        permission = team.permission
      }
    ]
  ])
}
