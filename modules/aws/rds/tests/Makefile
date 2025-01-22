all: buildlambda buildtests test

.PHONY: all build buildlambda buildtests test

build: buildlambda buildtests

buildlambda:
	cd fixtures/rdslambda && $(MAKE) all

buildtests:
	go mod download
	go mod tidy

# ridiculously long timeout because of it can take an hour to deploy and tear down a DB.
test: buildlambda buildtests
	go test -v -timeout 360m $(TEST_FLAGS)