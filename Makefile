# Borrowed from: 
# https://github.com/silven/go-example/blob/master/Makefile
# https://vic.demuzere.be/articles/golang-makefile-crosscompile/

BINARY=node-cert-exporter
GOARCH=amd64
VERSION=1.0.0-beta.1
COMMIT=$(shell git rev-parse HEAD)
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GOVERSION=$(shell go version | awk -F\go '{print $$3}' | awk '{print $$1}')
GITHUB_USERNAME=amimof
BUILD_DIR=${GOPATH}/src/github.com/${GITHUB_USERNAME}/${BINARY}
PKG_LIST=$$(go list ./... | grep -v /vendor/)
# Setup the -ldflags option for go build here, interpolate the variable values
LDFLAGS = -ldflags "-X main.VERSION=${VERSION} -X main.COMMIT=${COMMIT} -X main.BRANCH=${BRANCH} -X main.GOVERSION=${GOVERSION}"

# Build the project
all: build

dep:
	go get -v -d ./cmd/node-cert-exporter/... ;

fmt:
	cd ${BUILD_DIR}; \
	gofmt -s -d -e -w .; \

vet:
	cd ${BUILD_DIR}; \
	go vet ${PKG_LIST}; \

gocyclo:
	go get -u github.com/fzipp/gocyclo; \
	cd ${BUILD_DIR}; \
	${GOPATH}/bin/gocyclo .; \

golint:
	go get -u golang.org/x/lint/golint; \
	cd ${BUILD_DIR}; \
	${GOPATH}/bin/golint ${PKG_LIST}; \

ineffassign:
	go get github.com/gordonklaus/ineffassign; \
	cd ${BUILD_DIR}; \
	${GOPATH}/bin/ineffassign .; \

misspell:
	go get -u github.com/client9/misspell/cmd/misspell; \
	cd ${BUILD_DIR}; \
	find . -type f -not -path "./vendor/*" -not -path "./.git/*" -print0 | xargs -0 ${GOPATH}/bin/misspell; \

ci: fmt vet gocyclo golint ineffassign misspell 

test: dep
	cd ${BUILD_DIR}; \
	go test ${PKG_LIST}; \

linux: dep
	CGO_ENABLED=0 GOOS=linux GOARCH=${GOARCH} go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-linux-${GOARCH} cmd/node-cert-exporter/main.go

rpi: dep
	CGO_ENABLED=0 GOOS=linux GOARCH=arm go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-linux-arm cmd/node-cert-exporter/main.go

darwin: dep
	CGO_ENABLED=0 GOOS=darwin GOARCH=${GOARCH} go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-darwin-${GOARCH} cmd/node-cert-exporter/main.go

windows: dep
	CGO_ENABLED=0 GOOS=windows GOARCH=${GOARCH} go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-windows-${GOARCH}.exe cmd/node-cert-exporter/main.go

build: linux darwin rpi windows

docker_build:
	docker build -t amimof/logga:${VERSION} .
	docker tag amimof/logga:${VERSION} amimof/logga:latest

docker_push:
	docker push amimof/logga:${VERSION}
	docker push amimof/logga:latest

docker: docker_build docker_push

clean:
	rm -rf ${BUILD_DIR}/out/