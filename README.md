# prometheus-cert-exporter
[![Build Status](https://travis-ci.com/amimof/prometheus-cert-exporter.svg?token=YU8cQELmfms9zTY3ztML&branch=master)](https://travis-ci.com/amimof/prometheus-cert-exporter)

---

Prometheus exporter for x509 certificates written in Go. This project is currently in beta and is looking for contributors. Feel free to leave your feedback using the issues or pull requests.

# Docker
```
docker run -p 9117:9117 amimof/prometheus-cert-exporter --logtostderr=true --path=/etc/ssl,/dir/with/certs
```

# Binary
```
curl -LOs https://github.com/amimof/prometheus-cert-exporter/releases/download/v1.0.0-beta.1/prometheus-cert-exporter-linux-amd64 && sudo +x prometheus-cert-exporter-linux-amd64
./prometheus-cert-exporter-linux-amd64 --path=/etc/ssl,/dir/with/certs
```

# Contribute
All help in any form is highly appreciated and your are welcome participate in developing Huego together. To contribute submit a Pull Request. If you want to provide feedback, open up a Github Issue or contact me personally.