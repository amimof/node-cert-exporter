[Node Cert Exporter](https://github.com/amimof/node_cert_exporter) is a Prometheus Exporter that provides info about 
the certs on nodes.  

## Install / upgrade
helm repo add node-cert-exporter https://holmesb.github.io/node-cert-exporter/charts/
helm repo update
helm upgrade --install --values values.yaml node-cert-exporter node-cert-exporter/node_cert_exporter
