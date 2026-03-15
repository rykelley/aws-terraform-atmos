---
name: azure-keyvault-eso
description: >-
  Manage secrets using Azure Key Vault and External Secrets Operator (ESO)
  with AKS Workload Identity. Use when working with secrets, Key Vault,
  ExternalSecret resources, ClusterSecretStore, federated identity
  credentials, or when the user mentions secret management, ESO, or
  Workload Identity.
---

# Azure Key Vault + External Secrets Operator

## Architecture

```
Azure Key Vault
  └─ stores secrets (storage keys, connection strings, etc.)
       │
       ▼
External Secrets Operator (runs in AKS)
  └─ authenticates via Workload Identity (federated credential)
  └─ reads secrets from Key Vault
       │
       ▼
Kubernetes Secrets
  └─ synced automatically, consumed by pods as env vars or volumes
```

## Components Involved

| Layer | Component | Path |
|-------|-----------|------|
| Terraform | Key Vault + managed identity | `components/terraform/key-vault/` |
| Ansible | ClusterSecretStore CRD | `components/ansible/aks-config/` |
| Helmfile | ESO operator deployment | `components/helmfile/external-secrets/` |
| Helm | ExternalSecret per app | `apps/*/templates/external-secret.yaml` |

## Secrets Flow

1. **Terraform** creates Key Vault, stores secrets, creates a User Assigned Managed Identity
   for ESO, and sets up a federated identity credential linking AKS OIDC to the identity
2. **Helmfile** deploys ESO with the managed identity's client ID annotated on its
   service account
3. **Ansible** creates a `ClusterSecretStore` pointing at the Key Vault URL
4. **Helm chart** `ExternalSecret` resources reference the store and map Key Vault
   secrets to Kubernetes Secrets

## Adding a New Secret

### 1. Store in Key Vault (Terraform)

Add to `key-vault` component vars in the deploy stack:

```yaml
components:
  terraform:
    key-vault:
      vars:
        additional_secrets:
          my-new-secret: "secret-value"
```

Or add to `components/terraform/key-vault/main.tf` via the `all_secrets` local.

### 2. Consume in Application (Helm)

Create or update `ExternalSecret` in your app's Helm templates:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ .Release.Name }}-my-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: azure-key-vault
    kind: ClusterSecretStore
  target:
    name: {{ .Release.Name }}-my-secrets
    creationPolicy: Owner
  data:
    - secretKey: MY_SECRET          # key in K8s Secret
      remoteRef:
        key: my-new-secret          # key in Key Vault
```

### 3. Mount in Pod

```yaml
env:
  - name: MY_SECRET
    valueFrom:
      secretKeyRef:
        name: {{ .Release.Name }}-my-secrets
        key: MY_SECRET
```

## Workload Identity Setup

The Terraform `key-vault` component handles this automatically:

- `azurerm_user_assigned_identity.eso` - managed identity for ESO
- `azurerm_federated_identity_credential.eso` - links AKS OIDC issuer to identity
- `azurerm_role_assignment.eso_secrets_user` - grants Key Vault Secrets User role

The Helmfile ESO component annotates the service account with the identity's client ID.
