# apres-terraform

Apres shared terraform modules

## Versioning

WIP - Modules are versioned using the [Git Semantic Versioning](https://github.com/marketplace/actions/git-semantic-version) action. Modules are versioned individually.

* Patch versions are bumped automatically, no action required.
* Minor versions - to bump the minor version on, for example, the `vpc` module, include the string "(MINOR-vpc)" in the commit message.
* Major versions - to bump the major version on, for example, the `nat_instance` module, include the string "(MINOR-nat_instance)" in the commit message.

## Development

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