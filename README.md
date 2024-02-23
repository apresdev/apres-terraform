# apres-terraform

Apres shared terraform modules

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