locals {
  isFreePlan       = data.github_organization.root.plan == "free"
  isTeamPlan       = data.github_organization.root.plan == "team"
  isEnterprisePlan = data.github_organization.root.plan == "enterprise"

  features = {

    # Determines if the github organization supports branch protections
    branchProtection = local.isTeamPlan || local.isEnterprisePlan

    # Determines if the github organization supports Repositoy Rules
    repositoryRules = local.isEnterprisePlan

  }
}
