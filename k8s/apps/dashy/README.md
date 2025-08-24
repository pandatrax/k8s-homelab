# Dashy Helm Chart

This Helm chart deploys [Dashy](https://github.com/Lissy93/dashy), a self-hosted dashboard app, to Kubernetes.

## Features
- Configurable Dashy deployment via `values.yaml`
- Custom ConfigMap for Dashy configuration
- Optional Tailscale Ingress with TLS support, fully configurable via `values.yaml`
- Resource requests/limits and health probes

## Installation

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd apps/dashy
   ```
2. **Customize values:**
   Edit `values.yaml` to fit your environment (image, service, ingress, config, etc).
3. **Deploy with Helm:**
   ```sh
   helm install dashy . --namespace dashy --create-namespace
   ```
   Or use ArgoCD/Flux for GitOps deployment.

## Configuration

All settings are managed in `values.yaml`. Key options:

```yaml
dashy:
  replicaCount: 1
  image:
    repository: lissy93/dashy
    tag: "3.1.1"
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 80
  ingress:
    enabled: true
    className: tailscale
    host: dashy
    tls:
      enabled: true
      hosts:
        - dashy
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 512Mi
```

## ConfigMap

Dashy configuration is managed via a ConfigMap (`conf.yml`). Edit `templates/configmap.yaml` or update the config in `values.yaml` if templated.

## Ingress & TLS
- To expose Dashy externally, enable and configure Tailscale Ingress in `values.yaml`.
- For TLS, set `tls.enabled: true` and specify hosts for Tailscale MagicDNS.

## Health Probes
Readiness and liveness probes are configured for `/` on port 80. Adjust as needed for your environment.

## Resource Requests & Limits
Default CPU and memory requests/limits are set in `values.yaml` for stable scheduling:
```yaml
resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 512Mi
```

## Updating ConfigMap
After changing Dashy config, restart the pod to apply changes:
```sh
kubectl rollout restart deployment dashy -n dashy
```

## Maintainers
- Your Name <your.email@example.com>

## License
MIT
