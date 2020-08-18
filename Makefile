RELEASE_VERSION  =v0.1.6
SERVICE_NAME    ?=$(notdir $(shell pwd))
DOCKER_USERNAME ?=$(DOCKER_USER)
REMOTE_REPO_URL :=$(shell git config remote.origin.url)
PACKAGE_NAME    :=$(subst git@,,$(REMOTE_REPO_URL))
PACKAGE_NAME    :=$(subst .git,,$(PACKAGE_NAME))
PACKAGE_NAME    :=$(subst :,/,$(PACKAGE_NAME))

.PHONY: mod test run build dapr event image show imagerun lint clean, tag, init
all: test

tidy: ## Updates the go modules and vendors all dependencies 
	go mod tidy
	go mod vendor

test: mod ## Tests the entire project 
	go test -count=1 -race ./...

debug: tidy ## Runs uncompiled code in Dapr
	dapr run --app-id $(SERVICE_NAME) \
		     --app-port 50001 \
		     --app-protocol grpc \
		     --dapr-http-port 3500 \
             --components-path ./config \
         go run main.go

build: mod ## Builds local release binary
	CGO_ENABLED=0 go build -a -tags netgo -mod vendor -o bin/$(SERVICE_NAME) .

run: build ## Builds binary and runs it in Dapr
	dapr run --app-id $(SERVICE_NAME) \
			 --app-port 50001 \
		     --app-protocol grpc \
		     --dapr-http-port 3500 \
             --components-path ./config \
         bin/$(SERVICE_NAME) 

call: ## Invokes service through Dapr API 
	curl -d '{ "message": "ping" }' \
     -H "Content-type: application/json" \
     "http://localhost:3500/v1.0/invoke/$(SERVICE_NAME)/method/echo"

image: mod ## Builds and publish docker image 
	docker build -t "$(DOCKER_USERNAME)/$(SERVICE_NAME):$(RELEASE_VERSION)" .
	docker push "$(DOCKER_USERNAME)/$(SERVICE_NAME):$(RELEASE_VERSION)"

lint: ## Lints the entire project 
	golangci-lint run --timeout=3m

tag: ## Creates release tag 
	git tag $(RELEASE_VERSION)
	git push origin $(RELEASE_VERSION)

clean: ## Cleans up generated files 
	go clean
	rm -fr ./bin
	rm -fr ./vendor

init: clean ## Resets go modules 
	rm -f go.*
	go mod init $(PACKAGE_NAME)
	go mod tidy 
	go mod vendor 

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk \
		'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
