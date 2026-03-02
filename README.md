# node-cert-exporter
[![Go Workflow](https://github.com/amimof/node-cert-exporter/actions/workflows/go.yaml/badge.svg)](https://github.com/amimof/node-cert-exporter/actions/workflows/go.yaml) [![Go Report Card](https://goreportcard.com/badge/github.com/amimof/node-cert-exporter)](https://goreportcard.com/report/github.com/amimof/node-cert-exporter) [![huego](https://godoc.org/github.com/amimof/node-cert-exporter?status.svg)](https://godoc.org/github.com/amimof/node-cert-exporter)

---

`Prometheus` exporter for x509 certificates written in Go. `node-cert-exporter` will parse SSL certificates in a number of directories recursively and expose their expiry as a Prometheus metric at `/metrics`. It can run on `Kubernetes` as a `Deployment` or `DaemonSet`, or using `Docker`. 

*This project is currently in beta and is looking for contributors. Feel free to leave your feedback using issues or pull requests.*

# Kubernetes DaemonSet
```
kubectl apply -f https://raw.githubusercontent.com/amimof/node-cert-exporter/master/deploy/daemonset.yml
```

# Docker
```
docker run -p 9117:9117 ghcr.io/amimof/node-cert-exporter --logtostderr=true --include-glob /etc/ssl/*/*.pem
```

# Helm
```
helm repo add node-cert-exporter https://amimof.github.io/node-cert-exporter
helm repo update
helm install node-cert-exporter node-cert-exporter/node-cert-exporter
```

# Binary
```
curl -LOs https://github.com/amimof/node-cert-exporter/releases/latest/download/node-cert-exporter-linux-amd64 && chmod +x node-cert-exporter-linux-amd64
./node-cert-exporter-linux-amd64 --include-glob /etc/ssl/*/*.pem
```

# Building from source
```
git clone https://github.com/amimof/node-cert-exporter.git
cd node-cert-exporter
make
```

# Grafana Dashboard
Once the the node-cert-exporter is scraped by Prometheus, the metrics can easily be visualized using [Grafana](https://grafana.com). Get started by using the [Node Cert Exporter](https://grafana.com/dashboards/9999) dashboard hosted at grafana.com.

![](./img/grafana.png)

# Metrics

`node-cert-exporter` exports the following metrics:

## `ssl_certificate_expiry_seconds`
Absolute time in seconds until the certificate expires. This metric is useful for tracking when a certificate will expire.

**Example Prometheus alert rule:**
```yaml
- alert: CertificateExpiresIn7Days
  expr: ssl_certificate_expiry_seconds < (7 * 24 * 3600)
  annotations:
    summary: "Certificate {{ $labels.path }} expires in less than 7 days"
```

## `ssl_certificate_expiry_ratio`
Relative ratio of remaining certificate lifetime to total validity period. This metric ranges from:
- **1.0**: Certificate was just issued (100% of lifetime remaining)
- **0.5**: 50% of certificate lifetime remaining
- **0.0**: Certificate has expired

This metric is particularly useful for triggering alerts based on relative timeranges, such as when 50% of the certificate lifetime has been consumed.

**Example Prometheus alert rule:**
```yaml
- alert: Certificate50PercentLifetimeReached
  expr: ssl_certificate_expiry_ratio < 0.5
  annotations:
    summary: "Certificate {{ $labels.path }} has less than 50% of its lifetime remaining"

- alert: Certificate80PercentConsumed
  expr: ssl_certificate_expiry_ratio < 0.2
  annotations:
    summary: "Certificate {{ $labels.path }} has consumed 80% of its lifetime (20% remaining)"
```

# Contribute
All help in any form is highly appreciated and your are welcome participate in developing together. To contribute submit a Pull Request. If you want to provide feedback, open up a Github Issue or contact me personally.