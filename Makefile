TARGETS = $(wildcard modules/*/*)

all: $(addsuffix .all,$(TARGETS))

clean: $(addsuffix .clean,$(TARGETS))

upgrade-providers: $(addsuffix .upgrade-providers,$(TARGETS))

validate: $(addsuffix .validate,$(TARGETS))

update-readme: $(addsuffix .update-readme,$(TARGETS))

.PHONY: all clean upgrade-providers validate update-readme

# Create dynamic targets, based on the good work at
# https://github.com/enspirit/makefile-for-monorepos/blob/master/README.md
# The targets will be like "terraform/artifacts/us-east-2.clean" etc.
define make-terraform-targets

.PHONY: $1.clean $1.all

$1.clean:
	@echo "Cleaning $1"
	$(MAKE) -C $1 clean

$1.all:
	@echo "Preflight $1"
	$(MAKE) -C $1 preflight

$1.validate:
	@echo "Validating $1"
	$(MAKE) -C $1 preflight
	$(MAKE) -C $1 init-no-backend
	$(MAKE) -C $1 validate

$1.upgrade-providers:
	@echo "Upgrading backend for $1"
	$(MAKE) -C $1 upgrade-providers
	$(MAKE) -C $1 validate

$1.update-readme:
	@echo "Updating README for $1"
	$(MAKE) -C $1 update-readme

endef
$(foreach target,$(TARGETS),$(eval $(call make-terraform-targets,$(target))))

DOCS_VENV := ./build/venv

.PHONY: docs
docs: docs-setup
	rm -rfv ./build/site
	rm -rfv ./build/docs
	mkdir -p ./build/docs
	rsync -R `find ./docs -type f -name "*.md"` ./build
	rsync -R `find ./modules -type f -name "*.md"` ./build/docs
	. $(DOCS_VENV)/bin/activate && mkdocs build --site-dir ./build/site --config-file mkdocs.yml

.PHONY: docs-setup
docs-setup: requirements.txt $(DOCS_VENV)

$(DOCS_VENV):
	python -m venv $(DOCS_VENV)
	$(DOCS_VENV)/bin/pip install --upgrade pip
	$(DOCS_VENV)/bin/pip install -r requirements.txt
	@echo "Virtual environment created and requirements installed."

.PHONY: docs-clean
docs-clean:
	rm -rfv ./build
