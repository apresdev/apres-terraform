# GitHub Manager

This module manages GitHub repositories, teams, team membership, and permissions for teams to access the repos.

This module is meant to be used in a repository containing the configuration files for repos, teams and team members. A
template repository containing the artifacts is [https://github.com/apresdev/github-manager-template](https://github.com/apresdev/github-manager-template).

## Configuration and Schemas

This module diverts from standard terraform and uses yaml to configure repositories, teams and members. Schemas exist for
the yaml files, so the formats can be validated. The schemas live in [./schemas/](./schemas) and can be validated
using the [ajv](https://ajv.js.org/) CLI. To install the ajv CLI:

```shell
npm install -g ajv-cli ajv-keywords
```

And then can be used to validate a file. For example:
```shell
ajv validate ajv-keywords --all-errors -s ./schemas/repo.schema.yaml -d sample_repo.yaml
```

The [github-manager-template](https://github.com/apresdev/github-manager-template) contains that and more in the provided Makefile.

Sample configuration files are in [./examples](./examples).

## GitHub Repository Best Practices

This module implements the recommended security settings by GitHub:

- do not allow force pushes to main
- do not allow deletions on main
- restrict the access to those who can push to matching branches
- lock branch
- check the required pull request review, status checks and conversation resolution before merging
- check required signed commits
- require linear history and merge queue
- require deployments to succeed before merging

## GitHub Actions Authorization

This module is typically implemented as a GitHub Actions to orchestrate the workflows
which manage the organization's GitHub
repositories. A GitHub App is required to provide escalated privileges - the default
`GITHUB_TOKEN` provided by GitHub Actions is scoped to the current repository which is insufficient
for our needs, as the workflow needs access to the GitHub organization and permissions to create,
update, and delete repositories.

Following the principle of least privilege, the GitHub App should only enable the following
permissions:

- Repository Permissions
  - Administration: `Read and Write`
    - To create, update, and potentially delete repositories
  - Contents: `Read only`
    - Required to read the contents of the repo containing the config files and terraform calling this module
  - Issues: `Read and Write`
    - To add comments to the Pull Request
  - Pull Requests: `Read and Write`
    - To add comments to the Pull Request
- Organization Permissions
  - Administration: `Read only`
    - To read who has access to the organization
  - Members: `Read only`
    - To view the organizations members and their roles
  - Plan: `Read only`
    - To view the organizations billing plan

## GitHub Teams and Members

_Warning: the labels and properties used here are what the GitHub API uses, and are frequently not
what the UI shows._

GitHub teams are defined in directory specified in `${var.team_directory}`, and members are defined in the directory specified in `${var.member_directory}`.

Teams have a `privacy` attribute, shown as `Visible` in the UI, described at [Changing team visibility](https://docs.github.com/en/organizations/organizing-members-into-teams/changing-team-visibility).
In our schema the value is one of:
* `closed` - is the same as Visible, can be viewed by all members of the org.
* `secret` - secret teams are only visible to other members of that team and org owners. Secret teams cannot be nested. Client teams are secret so they cannot see each other.

Teams have members with roles:
* `member` - what you typically want
* `maintainer` - administrative privileges to the team, hand out with care. The full list of privileges are
  outlined at [About team maintainers](https://docs.github.com/en/organizations/organizing-members-into-teams/assigning-the-team-maintainer-role-to-a-team-member#about-team-maintainers)

GitHub members (aka: users) are invited to the GitHub Organization, and have their own privileges
in the organization from what their team membership gives. Except
for a few key individuals, all member privileges should be set to `member. Values are:
* `member` - what most users should be set to.
* `admin` - `admin` shows as `owner` in the GitHub UI.

See [Permissions for organization roles](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/) for details.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_github"></a> [github](#requirement\_github) | 6.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_teams"></a> [teams](#module\_teams) | ./modules/teams | n/a |

## Resources

| Name | Type |
|------|------|
| [github_branch_protection.default](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/branch_protection) | resource |
| [github_issue_labels.default](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/issue_labels) | resource |
| [github_membership.members](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/membership) | resource |
| [github_repository.managed_repository](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/repository) | resource |
| [github_repository_dependabot_security_updates.managed_repository](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/repository_dependabot_security_updates) | resource |
| [github_team_membership.default](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/team_membership) | resource |
| [github_team_repository.default](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/resources/team_repository) | resource |
| [github_organization.root](https://registry.terraform.io/providers/integrations/github/6.3.0/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | This is the target GitHub organization or individual user account to manage. For example, 'apresdev'. | `string` | n/a | yes |
| <a name="input_member_directory"></a> [member\_directory](#input\_member\_directory) | Directory where the member yaml files exist, relative to where the module lives. For example,<br>    if the module is called from `terraform/github-manager`, and the member yaml files are in<br>    `config/repos`, then the value of this variable should be `${path.module}/../config/member` | `string` | n/a | yes |
| <a name="input_repo_directory"></a> [repo\_directory](#input\_repo\_directory) | Directory where the repository yaml files exist, relative to where the module lives. For example,<br>    if the module is called from `terraform/github-manager`, and the repository yaml files are in<br>    `config/repos`, then the value of this variable should be `${path.module}/../config/repos` | `string` | n/a | yes |
| <a name="input_team_directory"></a> [team\_directory](#input\_team\_directory) | Directory where the team yaml files exist, relative to where the module lives. For example,<br>    if the module is called from `terraform/github-manager`, and the team yaml files are in<br>    `config/teams`, then the value of this variable should be `${path.module}/../config/teams` | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->