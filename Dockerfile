FROM golang:alpine AS build-env
RUN  apk add --no-cache git make ca-certificates
LABEL maintaner="@amimof (github.com/amimof)"
COPY . /go/src/github.com/amimof/node-cert-exporter
WORKDIR /go/src/github.com/amimof/node-cert-exporter
RUN make linux

FROM scratch
COPY --from=build-env /go/src/github.com/amimof/node-cert-exporter/out/node-cert-exporter-linux-amd64 /go/bin/node-cert-exporter
COPY --from=build-env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/go/bin/node-cert-exporter"]