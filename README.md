# node-cert-exporter
[![Build Status](https://travis-ci.org/amimof/node-cert-exporter.svg?branch=master)](https://travis-ci.org/amimof/node-cert-exporter) [![Go Report Card](https://goreportcard.com/badge/github.com/amimof/node-cert-exporter)](https://goreportcard.com/report/github.com/amimof/node-cert-exporter) [![huego](https://godoc.org/github.com/amimof/node-cert-exporter?status.svg)](https://godoc.org/github.com/amimof/node-cert-exporter)

---

`Prometheus` exporter for x509 certificates written in Go. `node-cert-exporter` will parse SSL certificates in a number of directories recursively and expose their expiry as a Prometheus metric at `/metrics`. It can run on `Kubernetes` as a `Deployment` or `DaemonSet`, or using `Docker`. 

*This project is currently in beta and is looking for contributors. Feel free to leave your feedback using issues or pull requests.*

# Kubernetes DaemonSet
```
kubectl apply -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/deploy/daemonset.yml
```

# Docker
```
docker run -p 9117:9117 amimof/node-cert-exporter --logtostderr=true --path=/etc/ssl,/dir/with/certs
```

# Binary
```
curl -LOs https://github.com/amimof/node-cert-exporter/releases/download/1.0.0-beta.1/node-cert-exporter-linux-amd64 && chmod +x node-cert-exporter-linux-amd64
./node-cert-exporter-linux-amd64 --path=/etc/ssl,/dir/with/certs
```

# Grafana Dashboard
Once the the node-cert-exporter is scraped by Prometheus, the metrics can easily be visualized using [Grafana](https://grafana.com). Get started by using the [Node Cert Exporter](https://grafana.com/dashboards/9999) dashboard hosted at grafana.com.

![](./img/grafana.png)

# Contribute
All help in any form is highly appreciated and your are welcome participate in developing together. To contribute submit a Pull Request. If you want to provide feedback, open up a Github Issue or contact me personally.