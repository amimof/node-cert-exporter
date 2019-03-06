FROM golang:alpine AS build-env
RUN  apk add --no-cache git make ca-certificates
LABEL maintaner="@amimof (amir.mofasser@gmail.com)"
COPY . /go/src/github.com/amimof/prometheus-cert-exporter
WORKDIR /go/src/github.com/amimof/prometheus-cert-exporter
RUN make linux

FROM scratch
COPY --from=build-env /go/src/github.com/amimof/prometheus-cert-exporter/out/prometheus-cert-exporter-linux-amd64 /go/bin/prometheus-cert-exporter
COPY --from=build-env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/go/bin/prometheus-cert-exporter"]