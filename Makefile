# Borrowed from: 
# https://github.com/silven/go-example/blob/master/Makefile
# https://vic.demuzere.be/articles/golang-makefile-crosscompile/

BINARY=prometheus-cert-exporter
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

test:
	cd ${BUILD_DIR}; \
	go test ; \
	cd - >/dev/null

fmt:
	cd ${BUILD_DIR}; \
	go fmt ${PKG_LIST} ; \
	cd - >/dev/null

dep:
	go get -v -d ./cmd/prometheus-cert-exporter/... ;

linux: dep
	CGO_ENABLED=0 GOOS=linux GOARCH=${GOARCH} go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-linux-${GOARCH} cmd/prometheus-cert-exporter/main.go

rpi: dep
	CGO_ENABLED=0 GOOS=linux GOARCH=arm go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-linux-arm cmd/prometheus-cert-exporter/main.go

darwin: dep
	CGO_ENABLED=0 GOOS=darwin GOARCH=${GOARCH} go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-darwin-${GOARCH} cmd/prometheus-cert-exporter/main.go

windows: dep
	CGO_ENABLED=0 GOOS=windows GOARCH=${GOARCH} go build ${LDFLAGS} -o ${BUILD_DIR}/out/${BINARY}-windows-${GOARCH}.exe cmd/prometheus-cert-exporter/main.go

docker_build:
	docker run --rm -v "${PWD}":/go/src/github.com/amimof/prometheus-cert-exporter -w /go/src/github.com/amimof/prometheus-cert-exporter golang:${GOVERSION} make fmt test
	docker build -t amimof/prometheus-cert-exporter:${VERSION} .
	docker tag amimof/prometheus-cert-exporter:${VERSION} amimof/prometheus-cert-exporter:latest

docker_push:
	docker push amimof/prometheus-cert-exporter:${VERSION}
	docker push amimof/prometheus-cert-exporter:latest

docker: docker_build docker_push

build: linux darwin rpi windows

clean:
	-rm -rf ${BUILD_DIR}/out/

.PHONY: linux darwin windows test fmt clean