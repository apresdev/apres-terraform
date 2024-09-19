locals {
  repo_schema = yamldecode(file("${path.module}/schemas/repo.yaml"))

  defaults = {

    visibility    = local.repo_schema.properties.visibility.default
    defaultBranch = local.repo_schema.properties.defaultBranch.default
    topics        = local.repo_schema.properties.topics.default

    pullRequests = {
      allowMergeCommit    = local.repo_schema.properties.pullRequests.properties.allowMergeCommit.default
      allowSquashMerge    = local.repo_schema.properties.pullRequests.properties.allowSquashMerge.default
      allowRebaseMerge    = local.repo_schema.properties.pullRequests.properties.allowRebaseMerge.default
      allowAutoMerge      = local.repo_schema.properties.pullRequests.properties.allowAutoMerge.default
      deleteBranchOnMerge = local.repo_schema.properties.pullRequests.properties.deleteBranchOnMerge.default
    }

    features = {
      hasIssues      = local.repo_schema.properties.features.properties.hasIssues.default
      hasProjects    = local.repo_schema.properties.features.properties.hasProjects.default
      hasDownloads   = local.repo_schema.properties.features.properties.hasDownloads.default
      hasDiscussions = local.repo_schema.properties.features.properties.hasDiscussions.default
    }

    isTemplate = local.repo_schema.properties.isTemplate.default
    labels     = local.repo_schema.properties.labels.default
  }

  team_schema = yamldecode(file("${path.module}/schemas/team.yaml"))
  team_defaults = {
    privacy = local.team_schema.properties.privacy.default
  }
}
