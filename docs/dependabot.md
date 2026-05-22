# Keep Apres Terraform Modules up to date with Dependabot

Keeping your code up to date to use the latest version of Apres Terraform
modules is a critical part of maintaining secure and resilient infrastructure.
Using GitHub Dependabot makes this quite easy.

The Apres terraform modules are in a private GitHub repository, so Dependabot
will need to be granted privileges to access the remote repo. Dependabot uses a
different set of secrets from GitHub Actions.

Setup Dependabot using the following steps.

## 1. Create a GitHub Personal Access Token

If you have access to the Apres Terraform modules, you've already done this. You
can reuse the token if you've stored it somewhere securely, or create a separate
one for this activity. Follow
[the instructions in the GitHub docs](https://docs.github.com/en/enterprise-server@3.9/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token)
to create a new token.

## 2. Create a Repository Secret for Dependabot

You will need to create a repository secret for Dependabot in the repo where
your Terraform code lives. Follow
[the instructions in the GitHub docs](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot#adding-a-repository-secret-for-dependabot)
to create a new repository secret.

## 3. Configure Dependabot

In the repo where your Terraform code is stored, create a file
`.github/dependabot.yml`. Full documentation of
[Configuration options for the dependabot.yml file](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
is available for reference.

The following snippet of code will configure Dependabot correctly, assuming:

1. The directories where your Terraform files exist are in `/terraform/*/*` in
   your repo (line 5)
2. You want Dependabot to run daily (line 7)

```yaml
version: 2
updates:
 - package-ecosystem: "terraform"
   directories:
     - "/terraform/*/*"
   schedule:
     interval: daily

```

Commit that to your repo. Once committed you can view the output of Dependabot
runs in the Insights tab, under "Dependency Graph", in the Dependabot tab.
