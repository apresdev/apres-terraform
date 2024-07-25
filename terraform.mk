# Here "all" is meant for the local developer's convenience and does not require AWS credentials.
# The CI pipeline will run individual steps, in part to make it simpler to debug in the GitHub UI.
all: format checkov init-no-backend validate update-readme

TFFILES=$(wildcard *.tf)

format: .build/format

.build/format: $(TFFILES)
	tofu fmt
	@mkdir -p .build
	@touch .build/format

format-check:
	tofu fmt -check -diff

checkov: .build/checkov

.build/checkov: $(TFFILES)
	checkov -d . --framework terraform --quiet --download-external-modules true
	@mkdir -p .build
	@touch .build/checkov

# Init the repo without requiring AWS credentials. INIT_FLAGS can include something like -upgrade or -reconfigure
init-no-backend: .build/init-no-backend

.build/init-no-backend: $(TFFILES)
	tofu init -backend=false $(INIT_FLAGS)
	@mkdir -p .build
	@touch .build/init-no-backend

# Used by the global all target as the default
preflight: format-check checkov

# Special target to upgrade providers
upgrade-providers: init-upgrade validate

# Init with an upgrade, no backend
init-upgrade: .build/init-upgrade

.build/init-upgrade:
	tofu init -backend=false -upgrade
	@mkdir -p .build
	@touch .build/init-upgrade

# This step requires AWS credentials.
init: .build/init

.build/init: $(TFFILES)
	tofu init $(INIT_FLAGS)
	@mkdir -p .build
	@touch .build/init

# Validate the config, whether it was created with a real backend or not.
validate: .build/validate

.build/validate: $(TFFILES) .terraform.lock.hcl
	tofu validate $(VALIDATE_FLAGS)
	@mkdir -p .build
	@touch .build/validate

# Plan flags can include -concise for CI builds
plan:
	tofu plan $(PLAN_FLAGS)

# Supports flags like -auto-approve
apply:
	tofu apply $(APPLY_FLAGS)

# Synonym for apply
deploy: apply

clean:
	rm -rf .terraform .external_modules .build

# Not every module has a ./tests directory, so we need to check for it.
TESTS_DIR = $(wildcard ./tests/*)

test: .build/test

# This will require AWS credentials but we don't check for that here.
.build/test: $(TFFILES) .terraform.lock.hcl
ifeq ($(strip $(TESTS_DIR)),)
	@echo "No tests directory found."
else
	cd tests && go mod download && go mod tidy && go test -v -timeout 30m $(TEST_FLAGS)
endif

update-readme: .build/update-readme

.build/update-readme: $(TFFILES) README.md
	terraform-docs markdown --output-file README.md --output-mode inject .
	@mkdir -p .build
	@touch .build/update-readme
