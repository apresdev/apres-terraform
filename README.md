# Apres Terraform Modules

## Development

We recommend using the configured dev Container, which has all the prerequisite software installed.

### README Updates

In each module running `make`, `make all`, or `make update-readme` will update the README file with the
latest terraform steps.


### Changelogs

The CHANGELOG.md files are generated automatically in the build workflows. Set the changelog message correctly in the PR
and the workflow will take care of the rest.

### Determining AWS Permissions

Determining what AWS permissions are required for a module can be a nice game of whackamole. There is however a sweet tool (iamlive)[https://github.com/iann0036/iamlive] that can help determine what they should be.

1. The iamlive tool is installed in the Dev Container in /usr/local/bin. If not using the Dev Container, install the tool using your installation method of choice.
1. In your test terraform stack, run `tofu init` first.
1. Assuming you have an profile in `~/.aws/config` named `test-aws-perms`, in a terminal window (in the Dev Container) run this command: `iamlive --provider aws --set-ini --profile test-aws-perms --mode proxy --refresh-rate 60 --output-file iamlive.log`. Note that while the CSM method claims to work with AWS, the author could only get proxy working.
1. In a new window set four environment variables (Windows may have different paths)
  ```
  export HTTP_PROXY=http://127.0.0.1:10080
  export HTTPS_PROXY=http://127.0.0.1:10080
  export AWS_CA_BUNDLE=~/.iamlive/ca.pem
  export SSL_CERT_FILE=~/.iamlive/ca.pem
  ```
1. Run your terraform plan/apply/destroy, and iamlive should output set of policies. Note that this may not capture _everything_ as updating resources may use a different set of API calls than creating does, but this should at least get you started.

### Makefiles

By default a module, as hinted at in the [templates](module/aws/templates) repo, will have a link to the generic
module [Makefile](./terraform.mk). That's sufficient for most cases. Occasionally a test will need special steps,
in which case the developer will want to do the following:

* Create a Makefile in the module/tests directory.
* The new Makefile must contain an `all` target, and do the necessary steps including executing the tests.

See the [rds/tests/Makefile](./modules/aws/rds/tests/Makefile) as an example. The RDS test needs to build
a Lambda locally first before running tests.