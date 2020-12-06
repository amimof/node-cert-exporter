# node-cert-exporter

[![Build Status](https://travis-ci.org/amimof/node-cert-exporter.svg?branch=master)](https://travis-ci.org/amimof/node-cert-exporter) [![Go Report Card](https://goreportcard.com/badge/github.com/amimof/node-cert-exporter)](https://goreportcard.com/report/github.com/amimof/node-cert-exporter) [![huego](https://godoc.org/github.com/amimof/node-cert-exporter?status.svg)](https://godoc.org/github.com/amimof/node-cert-exporter)

---

`Prometheus` exporter for x509 certificates written in Go. `node-cert-exporter` will parse SSL certificates in a number of directories recursively and expose their expiry as a Prometheus metric at `/metrics`. It can run on `Kubernetes` as a `Deployment` or `DaemonSet`, or using `Docker`. 

*This project is currently in beta and is looking for contributors. Feel free to leave your feedback using issues or pull requests.*

## Kubernetes DaemonSet

```bash
kubectl apply -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/deploy/daemonset.yml
```

## Openshift DaemonSet

__Tip__: This YAML files configured via jsonnet for prometheus-operator in OKD 3.11 and for the project `monitoring`

```bash
oc create -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/okd/rendered/node-cert-exporter-service.yaml
oc create -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/okd/rendered/node-cert-exporter-serviceMonitor.yaml
oc create -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/okd/rendered/node-cert-exporter-serviceAccount.yaml
oc adm policy add-scc-to-user hostmount-anyuid -n monitoring -z node-cert-exporter
oc create -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/okd/rendered/node-cert-exporter-daemonset.yaml
```

## Docker

```bash
docker run -p 9117:9117 amimof/node-cert-exporter --logtostderr=true --path=/etc/ssl,/dir/with/certs
```

## Helm

```bash
helm repo add node-cert-exporter https://amimof.github.io/node-cert-exporter
helm repo update
helm install node-cert-exporter node-cert-exporter/node-cert-exporter
```

## Binary

```bash
curl -LOs https://github.com/amimof/node-cert-exporter/releases/latest/download/node-cert-exporter-linux-amd64 && chmod +x node-cert-exporter-linux-amd64
./node-cert-exporter-linux-amd64 --path=/etc/ssl,/dir/with/certs
```

## Building from source

```bash
git clone https://github.com/amimof/node-cert-exporter.git
cd node-cert-exporter
make
```

## Grafana Dashboard

Once the the node-cert-exporter is scraped by Prometheus, the metrics can easily be visualized using [Grafana](https://grafana.com). Get started by using the [Node Cert Exporter](https://grafana.com/dashboards/9999) dashboard hosted at grafana.com.

![Grafana dashboard](./img/grafana.png)

## Contribute

All help in any form is highly appreciated and your are welcome participate in developing together. To contribute submit a Pull Request. If you want to provide feedback, open up a Github Issue or contact me personally.