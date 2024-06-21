module "ecr_repo" {
  source = "../../"

  name                             = var.name
  environment                      = var.environment
  shared_aws_org_for_pull          = var.shared_aws_org_for_pull
  github_repo_subject_claim_filter = var.github_repo_subject_claim_filter
  owner                            = "Engineering"
  application                      = "UnitTest"
}