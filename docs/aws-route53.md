# AWS Route53 Integration for ExternalDNS in Home Lab

## Overview
This document describes how to integrate AWS Route53 with a Kubernetes cluster running in a home lab environment.
We use [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) to automatically create and update DNS records in Route53 for services deployed in the cluster.

**Key points:**
- AWS credentials are stored **securely** in Kubernetes secrets (never committed to Git).
- We use an AWS IAM user with least-privilege permissions.
- DNS zones are managed in Route53, with this cluster updating records automatically.

---

## 1. Prerequisites
- Kubernetes cluster (home lab) with `kubectl` access.
- [ArgoCD](https://argo-cd.readthedocs.io/) for GitOps deployments.
- AWS account with Route53 hosted zones set up.
- Your domain name configured in Route53.

---

## 2. Create IAM Policy for ExternalDNS

1. Go to the AWS IAM console.
2. Create a **new policy** named `ExternalDNSRoute53Policy`.
3. Use the following JSON policy (replace `<hosted-zone-id>` with your actual Hosted Zone ID):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/<hosted-zone-id>"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## 3. Create an IAM User for ExternalDNS

```
aws iam create-user --user-name externaldns

# This will not have a response
aws iam put-user-policy \
  --user-name externaldns \
  --policy-name ExternalDNSRoute53Access \
  --policy-document file://route53-policy.json

# Check that the policy was created
aws iam list-user-policies --user-name externaldns

# View the policy document
aws iam get-user-policy --user-name externaldns --policy-name ExternalDNSRoute53Access

aws iam create-access-key --user-name externaldns
```

**Record the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`** — these will be stored as a Kubernetes secret.

## 4. Store AWS Credentials in Kubernetes

We will create a secret in the same namespace where ExternalDNS runs (commonly `external-dns`):

```
kubectl create namespace external-dns

kubectl create secret generic aws-credentials \
    --namespace external-dns \
    --from-literal=aws_access_key_id=<AWS_ACCESS_KEY_ID> \
    --from-literal=aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
```

We will create a secret in the same namespace where CertManager runs (commonly `cert-manager`):

```
kubectl create ns cert-manager

kubectl create secret generic aws-credentials \
    --namespace cert-manager \
    --from-literal=aws_access_key_id=<AWS_ACCESS_KEY_ID> \
    --from-literal=aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
```

**⚠ DO NOT commit these credentials to Git.** They are stored only in Kubernetes.

## 5. Troubleshooting tips
  * If ExternalDNS fails with auth errors: re-check secret keys & region; check pod logs in external-dns namespace.

  * If cert-manager fails to solve DNS: check ClusterIssuer status and cert-manager logs in cert-manager namespace.

  * If MetalLB config errors: check kubectl -n metallb-system get crd to ensure ipaddresspools.metallb.io exists (created by chart).

  * Use kubectl -n argocd logs deploy/argocd-application-controller if ArgoCD refuses to sync due to ordering issues.



## 6. Security Notes

  * Rotate AWS keys periodically.
  * Limit the IAM policy to only the Hosted Zones this cluster manages.
  * Consider using IAM Roles + IRSA if moving to EKS in the future.
