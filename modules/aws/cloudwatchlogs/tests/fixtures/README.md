# CloudWatch Logs Example

This is an example on how to deploy the CloudWatch Logs module, used by the integration tests.

## Running this module manually

1. Install [OpenTofu](https://www.opentofu.org/) and make sure it's on your `PATH`.
1. Run `tofu init`.
1. Run `tofu apply`.
1. When you're done, run `tofu destroy`.

## Running automated tests against this module

1. Install [OpenTofu](https://www.opentofu.org/) and make sure it's on your `PATH`.
1. Install [Golang](https://golang.org/) and make sure this code is checked out into your `GOPATH`.
1. Login to AWS on the CLI (hint: AWS_PROFILE=<some-predefined-profile> aws sso login)
1. `cd test`
1. `dep ensure`
1. `AWS_PROFILE=<some-predefined-profile> go test -v -run TestCloudWatchLogsRegional`
