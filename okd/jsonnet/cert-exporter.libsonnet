local k = import '../../vendor/ksonnet/ksonnet.beta.4/k.libsonnet';

{
  _config+:: {
    namespace: 'default',

    versions+:: {
      nodeCertExporter: '1.0.0',
    },

    imageRepos+:: {
      nodeCertExporter: 'amimof/node-cert-exporter',
    },

    nodeCertExporter+:: {
      port: 9117,
      labels: {
        'k8s-app': 'node-cert-exporter',
      },
      container: {
        requests: { cpu: '100m', memory: '128Mi' },
        limits: { cpu: '250m', memory: '256Mi' },
      },
    },
  },

  nodeCertExporter+:: {
    daemonset:
      local daemonset = k.apps.v1.daemonSet;
      local container = daemonset.mixin.spec.template.spec.containersType;
      local volume = daemonset.mixin.spec.template.spec.volumesType;
      local containerPort = container.portsType;
      local targetPort = $._config.nodeCertExporter.port;
      local portName = 'metric';
      local containerVolumeMount = container.volumeMountsType;
      local podSelector = daemonset.mixin.spec.template.spec.selectorType;
      local containerEnv = container.envType;

      local podLabels = $._config.nodeCertExporter.labels;

      local etcdVolumeName = 'etcd';
      local etcdVolume = volume.fromHostPath(etcdVolumeName, '/etc/etcd');
      local etcdVolumeMount = containerVolumeMount.new(etcdVolumeName, '/opt/etc/etcd').
        withReadOnly(true);

      local masterVolumeName = 'master';
      local masterVolume = volume.fromHostPath(masterVolumeName, '/etc/origin/master');
      local masterVolumeMount = containerVolumeMount.new(masterVolumeName, '/opt/etc/master').
        withReadOnly(true);

      local nodeVolumeName = 'node';
      local nodeVolume = volume.fromHostPath(nodeVolumeName, '/etc/origin/node/certificates');
      local nodeVolumeMount = containerVolumeMount.new(nodeVolumeName, '/opt/etc/node').
        withReadOnly(true);

      local nodename = containerEnv.fromFieldPath('NODE_NAME', 'spec.nodeName');

      local nodeCertExporter =
        container.new('node-cert-exporter', $._config.imageRepos.nodeCertExporter + ':' + $._config.versions.nodeCertExporter) +
        container.withArgs([
            '--v=2',
            '--logtostderr=true',
            '--path=/opt/etc/etcd/,/opt/etc/master/,/opt/etc/node/'
        ]) +
        container.withVolumeMounts([etcdVolumeMount, masterVolumeMount, nodeVolumeMount]) +
        container.mixin.resources.withRequests($._config.nodeCertExporter.container.requests) +
        container.withPorts(containerPort.newNamed(targetPort, portName)) +
        container.withEnv([nodename]) +
        container.mixin.resources.withLimits($._config.nodeCertExporter.container.limits);

      local c = [nodeCertExporter];

      daemonset.new() +
      daemonset.mixin.metadata.withName('node-cert-exporter') +
      daemonset.mixin.metadata.withNamespace($._config.namespace) +
      daemonset.mixin.metadata.withLabels(podLabels) +
      daemonset.mixin.spec.selector.withMatchLabels(podLabels) +
      daemonset.mixin.spec.template.metadata.withLabels(podLabels) +
      daemonset.mixin.spec.template.spec.withNodeSelector({ 'beta.kubernetes.io/os': 'linux' }) +
      daemonset.mixin.spec.template.spec.withContainers(c) +
      daemonset.mixin.spec.template.spec.withVolumes([etcdVolume, masterVolume, nodeVolume]) +
      daemonset.mixin.spec.template.spec.withServiceAccountName('node-cert-exporter') +
      daemonset.mixin.spec.template.spec.securityContext.withRunAsUser(0),

    serviceAccount:
      local serviceAccount = k.core.v1.serviceAccount;

      serviceAccount.new('node-cert-exporter') +
      serviceAccount.mixin.metadata.withNamespace($._config.namespace),

    serviceMonitor:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'node-cert-exporter',
          namespace: $._config.namespace,
          labels: $._config.nodeCertExporter.labels,
        },
        spec: {
          selector: {
            matchLabels: $._config.nodeCertExporter.labels,
          },
          endpoints: [
            {
              port: 'metric',
              interval: '15s',
            },
          ],
        },
      },

    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local nodeCertExporterPort = servicePort.newNamed('metric', $._config.nodeCertExporter.port, 'metric');

      service.new('node-cert-exporter', $.nodeCertExporter.daemonset.spec.selector.matchLabels, nodeCertExporterPort) +
      service.mixin.metadata.withNamespace($._config.namespace) +
      service.mixin.metadata.withLabels($._config.nodeCertExporter.labels),
  },
}
