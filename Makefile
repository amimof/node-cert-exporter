# Borrowed from: 
# https://github.com/silven/go-example/blob/master/Makefile
# https://vic.demuzere.be/articles/golang-makefile-crosscompile/

BINARY=node-cert-exporter
GOARCH=amd64
VERSION=$(shell git describe --abbrev=0 --tags)
COMMIT=$(shell git rev-parse HEAD)
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GOVERSION=$(shell go version | awk -F\go '{print $$3}' | awk '{print $$1}')
GITHUB_USERNAME=amimof
BUILD_DIR=${GOPATH}/src/github.com/${GITHUB_USERNAME}/${BINARY}
PKG_LIST=$$(go list ./... | grep -v /vendor/)
# Setup the -ldflags option for go build here, interpolate the variable values
LDFLAGS = -ldflags "-X main.VERSION=${VERSION} -X main.COMMIT=${COMMIT} -X main.BRANCH=${BRANCH} -X main.GOVERSION=${GOVERSION}"

.PHONY: checkfmt

# Build the project
all: build

dep:
	curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash; \
	go get -v -d ./cmd/node-cert-exporter/... ; \

fmt:
	cd ${BUILD_DIR}; \
	gofmt -s -e -d -w .; \

vet:
	cd ${BUILD_DIR}; \
	go vet ${PKG_LIST}; \

gocyclo:
	go get -u github.com/fzipp/gocyclo; \
	cd ${BUILD_DIR}; \
	${GOPATH}/bin/gocyclo -over 15 .; \

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

checkfmt:
	cd ${BUILD_DIR}
	if [ "`gofmt -l .`" != "" ]; then \
		echo "Code not formatted, please run 'make fmt'"; \
		exit 1; \
	fi

ci: fmt vet gocyclo golint ineffassign misspell 

test: dep
	cd ${BUILD_DIR}; \
	go test ${PKG_LIST}; \

integration-test: docker_build
	mkdir -p ${BUILD_DIR}/out/integration-test/ssl
	openssl req -new -newkey rsa:1024 -days 365 -nodes -x509 \
  	-subj '/CN=localhost/C=SE/L=Gothenburg/O=system:nodes/OU=amimof/ST=Vastra Gotalands Lan' \
  	-keyout ${BUILD_DIR}/out/integration-test/ssl/self-signed-key.pem \
  	-out ${BUILD_DIR}/out/integration-test/ssl/self-signed.pem
	docker run -d --name node-cert-exporter --hostname 0a9ad966a64e -v ${BUILD_DIR}/out/integration-test/ssl:/certs -p 9117:9117 -e NODE_NAME=docker-node amimof/node-cert-exporter:${VERSION} --logtostderr=true --v=4 --path=/certs
	sleep 3
	curl -s http://127.0.0.1:9117/metrics | grep ssl_certificate_expiry_seconds
	curl -s http://127.0.0.1:9117/metrics | grep 'issuer="CN=localhost,OU=amimof,O=system:nodes,L=Gothenburg,ST=Vastra Gotalands Lan,C=SE"'
	curl -s http://127.0.0.1:9117/metrics | grep 'path="/certs/self-signed.pem"'
	curl -s http://127.0.0.1:9117/metrics | grep 'alg="SHA256-RSA"'
	curl -s http://127.0.0.1:9117/metrics | grep 'dns_names=""'
	curl -s http://127.0.0.1:9117/metrics | grep 'email_addresses=""'
	curl -s http://127.0.0.1:9117/metrics | grep 'hostname="0a9ad966a64e"'
	curl -s http://127.0.0.1:9117/metrics | grep 'nodename="docker-node"'
	docker kill node-cert-exporter
	docker rm node-cert-exporter
	docker run -d --name node-cert-exporter -v ${BUILD_DIR}/out/integration-test/ssl:/certs -p 9117:9117 amimof/node-cert-exporter:${VERSION} --logtostderr=true --v=4 --path=/certs --exclude-path=/certs
	sleep 3
	if [ "`curl -s http://127.0.0.1:9117/metrics | grep ssl_certificate_expiry_seconds`" != "" ]; then \
		exit 1; \
	fi
	docker kill node-cert-exporter
	docker rm node-cert-exporter

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
	docker build -t amimof/node-cert-exporter:${VERSION} .
	docker tag amimof/node-cert-exporter:${VERSION} amimof/node-cert-exporter:latest

docker_push:
	docker push amimof/node-cert-exporter:${VERSION}
	docker push amimof/node-cert-exporter:latest

helm_package:
	helm package charts/node-cert-exporter -d charts/node-cert-exporter --version ${VERSION} 

helm_index:
	helm repo index charts/

helm_lint:
	helm lint charts/node-cert-exporter/
	
docker: docker_build docker_push

clean:
	rm -rf ${BUILD_DIR}/out/