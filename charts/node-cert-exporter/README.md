# Node Cert Exporter Helm Chart
[Node Cert Exporter](https://github.com/amimof/node-cert-exporter) is a Prometheus Exporter that provides info about SSL certificates on Kubernetes nodes.

## Install / upgrade
```
helm repo add node-cert-exporter https://amimof.github.io/node-cert-exporter
helm repo update
helm install node-cert-exporter node-cert-exporter/node-cert-exporter
```