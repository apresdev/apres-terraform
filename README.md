# Apres Terraform Modules

## Development

We recommend using the configured dev Container, which has all the prerequisite software installed.

### Setup

You will want pre-commit hooks setup, which will lint your terraform code and update docs before committing.

On OSX:
```shell
brew install pre-commit`
```

And then install the hooks (it will install `.git/hooks/pre-commit`):
```shell
pre-commit install
```

To run the pre-commit hooks before you commit:
```shell
pre-commit run terraform-docs-go -a -v
```

### Determining AWS Permissions

Determining what AWS permissions are required for a module can a nice game of whackamole. There is however a sweet tool (iamlive)[https://github.com/iann0036/iamlive] that can help determine what they should be.

1. The iamlive tool is installed in the Dev Container in /usr/local/bin. If not using the Dev Container, install the tool using your installation method of choice.
1. Assuming you have an profile in your `~/.aws/config` file named `test-aws-perms`, in a terminal window (in the Dev Container) run this command: `iamlive --provider aws --set-ini --profile test-aws-perms --mode proxy`. Note that while the CSM method cliams to work with AWS, the author could only get proxy working.
1. In a new window set three environment variables (Windows may have different paths)
  ```
  export HTTP_PROXY=http://127.0.0.1:10080
  export HTTPS_PROXY=http://127.0.0.1:10080
  export AWS_CA_BUNDLE=~/.iamlive/ca.pem
  ```
1. Run your terraform plan/apply/destroy, and iamlive should output set of policies. Note that this may not capture _everything_ as updating resources may use a different set of API calls than creating does, but this should at least get you started.
