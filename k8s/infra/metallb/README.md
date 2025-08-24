
# MetalLB GitOps Deployment (App of Apps Pattern)

This directory contains the manifests and configuration for deploying MetalLB to your Kubernetes cluster using ArgoCD and the app-of-apps GitOps pattern.

## Structure
- **metallb-helm.yaml**: ArgoCD Application manifest to install MetalLB via the official Helm chart in the `metallb-system` namespace.
- **metallb-config.yaml**: ArgoCD Application manifest to apply MetalLB custom resources (CRs) such as IPAddressPool and L2Advertisement, after MetalLB is installed.
- **config/**: Directory containing Kustomize configuration and MetalLB CRs (e.g., `ip-pool.yaml`).
  - **kustomization.yaml**: Kustomize file to manage and apply the custom resources in `config/`.
  - **ip-pool.yaml**: Defines the IPAddressPool and L2Advertisement custom resources for MetalLB.

## How it Works
1. **App of Apps Pattern**: The parent ArgoCD Application (e.g., `metallb-app.yaml` in your bootstrap folder) points to this directory and manages both `metallb-helm.yaml` and `metallb-config.yaml` as child apps.
2. **Helm Chart Installation**: The `metallb-helm.yaml` Application installs MetalLB in the `metallb-system` namespace using the official Helm chart.
3. **Custom Resources (CRs)**: The `metallb-config.yaml` Application applies your MetalLB CRs (from `config/`) in the same namespace. It uses the `dependsOn` field to ensure the Helm install is complete before applying CRs, preventing errors from missing CRDs.
4. **Namespace Management**: Both child Applications are configured with `syncOptions: - CreateNamespace=true` to ensure the `metallb-system` namespace is created automatically if it does not exist.

## Customization
- **IP Address Pool**: Edit `config/ip-pool.yaml` to match your LAN's available IP range. Avoid overlapping with DHCP or other static assignments.
- **Helm Chart Version**: The Helm chart version is set in `metallb-helm.yaml` (`targetRevision`). Update as needed to keep MetalLB current.

## Deployment
1. Commit and push changes to this directory to your Git repository.
2. ArgoCD will automatically sync and deploy MetalLB and its configuration using the app-of-apps pattern.

## Troubleshooting
- If MetalLB pods do not start, check the ArgoCD Application status and pod logs in the `metallb-system` namespace.
- Ensure your cluster nodes can access the IP range specified in `config/ip-pool.yaml`.
- If you see errors about missing CRDs, ensure the `dependsOn` field is set in `metallb-config.yaml` so CRs are only applied after the Helm install.

## References
- [MetalLB Documentation](https://metallb.universe.tf/)
- [MetalLB Helm Chart](https://artifacthub.io/packages/helm/metallb/metallb)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
