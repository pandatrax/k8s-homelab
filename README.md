# gitops-platform

This repo contains the manifests and Helm values to bootstrap apps on the home lab Kubernetes cluster using Argo CD.

- `apps/` - Application manifests and Helm values
- `bootstrap/argocd/` - Argo CD Application manifests to bootstrap apps including Argo CD itself and Gitea

## How to use

1. Install Argo CD on the cluster.
2. Add this repo to Argo CD.
3. Argo CD will sync and deploy Gitea under the `gitea` namespace.

## ToDo

1. Monitoring: Consider enabling metrics and monitoring for ExternalDNS to track sync status and errors.

2. Helm Chart Version: Periodically check for new releases to keep up with bug fixes and features.

3. Consider exposing Hubble UI with an Ingress or LoadBalancer service for easy access

4. If you use network policies, you can add and manage them in Git as well

5. If you have workloads that depend on Cilium features (like Ingress or network policies), use ArgoCD’s dependsOn or sync waves to ensure Cilium is deployed first

6. Enable and monitor Hubble metrics/logs for network visibility. Consider integrating with Prometheus/Grafana for cluster observability

7. Review and tune Cilium’s security settings (e.g., identity allocation, encryption, policy enforcement) as needed for your environment


## Notes
```
pandatrax@kholinar:~/git_repos/gitops-platform/test$ kubectl get nodes
NAME          STATUS   ROLES           AGE    VERSION
k8s-control   Ready    control-plane   106d   v1.28.15
k8s-worker1   Ready    <none>          106d   v1.28.15
k8s-worker2   Ready    <none>          99d    v1.28.15
pandatrax@kholinar:~/git_repos/gitops-platform/test$ kubectl taint nodes k8s-control node-role.kubernetes.io/control-plane=:NoSchedule
node/k8s-control tainted
```
If you need to remove the taint in the future, use:

```
kubectl taint nodes k8s-control node-role.kubernetes.io/control-plane:NoSchedule-
```