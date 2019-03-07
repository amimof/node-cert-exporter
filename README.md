# prometheus-cert-exporter
[![Build Status](https://travis-ci.org/amimof/prometheus-cert-exporter.svg?branch=master)](https://travis-ci.org/amimof/prometheus-cert-exporter) [![Go Report Card](https://goreportcard.com/badge/github.com/amimof/prometheus-cert-exporter)](https://goreportcard.com/report/github.com/amimof/prometheus-cert-exporter) [![huego](https://godoc.org/github.com/amimof/prometheus-cert-exporter?status.svg)](https://godoc.org/github.com/amimof/prometheus-cert-exporter)

---

Prometheus exporter for x509 certificates written in Go. This project is currently in beta and is looking for contributors. Feel free to leave your feedback using issues or pull requests.

# Docker
```
docker run -p 9117:9117 amimof/prometheus-cert-exporter --logtostderr=true --path=/etc/ssl,/dir/with/certs
```

# Binary
```
curl -LOs https://github.com/amimof/prometheus-cert-exporter/releases/download/1.0.0-beta.1/prometheus-cert-exporter-linux-amd64 && chmod +x prometheus-cert-exporter-linux-amd64
./prometheus-cert-exporter-linux-amd64 --path=/etc/ssl,/dir/with/certs
```

# Contribute
All help in any form is highly appreciated and your are welcome participate in developing together. To contribute submit a Pull Request. If you want to provide feedback, open up a Github Issue or contact me personally.