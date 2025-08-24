# CoreDNS Split DNS Setup for Homelab Cluster

This document describes the CoreDNS configuration used in the homelab Kubernetes cluster to support:

- Standard cluster DNS (`cluster.local`) for services and pods
- Tailscale DNS (`*.ts.net`) for egress services managed by the Tailscale operator
- Independence from node `/etc/resolv.conf` differences

---

## Motivation

- The Tailscale agent is installed only on the control-plane node.
- Worker nodes do not have Tailscale installed, so their `/etc/resolv.conf` points to default upstream DNS.
- CoreDNS needs to consistently resolve `*.ts.net` regardless of which node a pod lands on.
- Solution: Split DNS in CoreDNS, hardcoding Tailscale and standard upstreams.

---

## CoreDNS ConfigMap

File: `coredns-split-dns.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    ts.net:53 {
      forward . 100.100.100.100
    }

    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . 192.168.1.1 1.1.1.1
        cache 30
        loop
        reload
        loadbalance
    }
```

---

## Notes:
- `ts.net:53` block forwards all Tailscale DNS queries to Tailscale MagicDNS (`100.100.100.100`).
- `.:53` block handles all other queries:
  - Cluster DNS (`kubernetes.default.svc.cluster.local`)
  - External DNS through specified upstreams (`192.168.1.1` and `1.1.1.1`)

No longer depends on `/etc/resolv.conf`.

---

## Applying the ConfigMap

1. Backup current CoreDNS ConfigMap:

```bash
kubectl -n kube-system get configmap coredns -o yaml > coredns-backup.yaml
```

1. Apply the new ConfigMap:

```bash
kubectl apply -f coredns-split-dns.yaml
```

1. Restart CoreDNS pods to pick up changes:

```bash
kubectl -n kube-system rollout restart deploy coredns
```

---

## Verifying DNS
### Cluster DNS

```bash
kubectl run -it --rm dns-test --image=busybox:1.36 --restart=Never \
  -- nslookup kubernetes.default.svc.cluster.local
```

Expected result: resolves to cluster IP (`10.96.0.1` or equivalent)

### Tailscale DNS

```bash
kubectl run -it --rm dns-test --image=busybox:1.36 --restart=Never \
  -- nslookup <your-ts-domain>.ts.net
```

> ⚠️ This will only succeed if CoreDNS pods can reach Tailscale DNS (`100.100.100.100`).
> In a 2-node cluster, either:
> - Install Tailscale agent on all nodes, or
> - Pin CoreDNS pods to nodes that have Tailscale installed using node affinity.

---

## Notes on GitOps

1. `kube-system` and CoreDNS are not managed by ArgoCD, to avoid conflicts with cluster-managed resources.
1. This ConfigMap is documented here for reproducibility in case of cluster rebuilds.
1. Any future changes should be version-controlled in `gitops-platform/docs/coredns/`.