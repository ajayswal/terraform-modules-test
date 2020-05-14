# We don't have access to control plane components, so exluding them from monitoring
kubeApiServer:
  enabled: false
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
coreDns:
  enabled: false
kubeDns:
  enabled: true
kubeEtcd:
  enabled: false

defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: false
    general: true
    k8s: true
    kubeApiserver: false
    kubePrometheusNodeAlerting: true
    kubePrometheusNodeRecording: true
    kubeScheduler: false
    kubernetesAbsent: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    node: true
    prometheusOperator: true
    prometheus: true

grafana:
  auth:
    anonymous:
      enabled: false
  adminPassword: ${grafana_admin_password}
  ingress:
    enabled: true
    hosts:
      - grafana.${ingress_hostname}
    tls:
      - secretName: ${ingress_secret}
        hosts:
          - grafana.${ingress_hostname}