all: build zip

.PHONY: build
build:
	go mod download
	go mod tidy
	go fmt ./...
	GOOS=linux GOARCH=arm64 go build -o bootstrap main.go

zip:
	zip -j rdslambda.zip bootstrap

clean:
	rm -f bootstrap rdslambda.zip
