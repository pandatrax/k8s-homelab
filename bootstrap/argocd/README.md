
# When SSH to Gitea Fails

When redeploying Gitea, the SSH host key may change (for example, if the pod is recreated or the server is rebuilt). This causes ArgoCD to fail connecting to the repository with a "knownhosts: key mismatch" error. To fix it:

1. Open a shell on the ArgoCD repo-server pod:
   ```bash
   kubectl exec -n argocd -it deploy/argocd-repo-server -- sh
   ```

2. Scan for the new SSH host key from the Gitea SSH service:
   ```bash
   ssh-keyscan -p 2222 gitea-ssh.gitea.svc.cluster.local
   ```
   Copy the output.

3. In a separate terminal, edit the ArgoCD SSH known hosts configmap:
   ```bash
   kubectl edit configmap argocd-ssh-known-hosts-cm -n argocd
   ```
   - Find the entry for `gitea-ssh.gitea.svc.cluster.local` and replace the old key with the new one you copied.
   - Save and exit the editor.

4. Resync the affected ArgoCD application in the UI or with:
   ```bash
   argocd app sync <app-name>
   ```

This will resolve the SSH key mismatch and allow ArgoCD to connect to your Gitea repository again.

# Argo CD Bootstrap Folder
This folder contains manifests that **bootstrap Argo CD** and its managed Applications.

## How it works
* The initial Argo CD bootstrap Application manifest (e.g., `argocd-bootstrap.yaml`)
  **must be applied manually once** to your Argo CD namespace using:

  ```
  kubectl apply -f bootstrap/argocd/argocd-bootstrap.yaml -n argocd
  ```

* Once applied, Argo CD will start monitoring this folder (`bootstrap/argocd`) in the Git
  repository and **automatically sync any changes** committed here.

*  This means:
  * You can **manage Argo CD’s own Applications declaratively in Git**.
  * Adding or modifying Application manifests here triggers Argo CD to deploy or update those
    Applications in the cluster.
  * This creates a **self-managing GitOps workflow for Argo CD itself and all bootstrap apps**.

## Adding new apps
To add a new Argo CD Application for your workloads:
* Add the Application manifest YAML to this folder.
* Commit and push to Git.
* Argo CD will automatically detect and sync the new Application.
