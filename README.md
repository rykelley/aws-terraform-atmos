# Homelab AKS - Atmos + Azure Verified Modules

Production-ready AKS environment on Azure, orchestrated by [Atmos](https://atmos.tools/) using Terraform ([Azure Verified Modules](https://aka.ms/avm)), Ansible, and Helmfile.

## Architecture

- **Terraform** provisions Azure infrastructure (resource group, VNet, AKS, storage, Key Vault)
- **Ansible** configures the AKS cluster (namespaces, storage classes, ClusterSecretStore)
- **Helmfile** deploys workloads (External Secrets Operator, NGINX ingress, demo microservices app)
- **Atmos** orchestrates all three tools via stack configuration and workflows

### Secrets Flow

Secrets are managed via [External Secrets Operator](https://external-secrets.io/) (ESO) with Azure Key Vault:

1. Terraform creates Key Vault and stores secrets (storage account credentials, app secrets)
2. Terraform creates a User Assigned Managed Identity with federated credentials for AKS workload identity
3. Helmfile installs ESO, configured with the managed identity via workload identity annotations
4. Ansible deploys a `ClusterSecretStore` pointing at Key Vault
5. App Helm charts define `ExternalSecret` resources that sync Key Vault secrets into Kubernetes Secrets
6. Pods consume standard Kubernetes Secrets (no Azure SDK required in apps)

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Atmos](https://atmos.tools/install) | >= 1.0 | Orchestration |
| [Terraform](https://terraform.io) | >= 1.5 | Infrastructure |
| [Ansible](https://docs.ansible.com) | >= 2.15 | Cluster config |
| [Helm](https://helm.sh) | >= 3.0 | Chart packaging |
| [Helmfile](https://github.com/helmfile/helmfile) | >= 0.160 | Helm release management |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) | >= 2.50 | Azure authentication |

You also need an Azure subscription with Contributor access.

## Quick Start

```bash
# 1. Login to Azure
az login

# 2. Bootstrap Terraform state (one-time)
./scripts/bootstrap-state.sh

# 3. Deploy everything to dev
atmos workflow full -s dev

# Or step by step:
atmos workflow infra -s dev        # Infrastructure (RG, VNet, storage, AKS, Key Vault)
atmos workflow configure -s dev    # AKS configuration (namespaces, ClusterSecretStore)
atmos workflow deploy -s dev       # Workloads (ESO, ingress, demo app)
```

## Project Structure

```
├── atmos.yaml                     # Atmos CLI configuration
├── stacks/
│   ├── orgs/homelab/              # Organization defaults + backend
│   ├── catalog/                   # Reusable component catalogs
│   │   ├── terraform/             # Terraform component defaults
│   │   ├── ansible/               # Ansible component defaults
│   │   └── helmfile/              # Helmfile component defaults
│   ├── deploy/                    # Environment stacks
│   │   ├── dev/aks.yaml
│   │   └── prod/aks.yaml
│   └── workflows/deploy.yaml     # Atmos workflow definitions
├── components/
│   ├── terraform/                 # Terraform root modules
│   │   ├── bootstrap/             # State backend (one-time)
│   │   ├── resource-group/        # Azure Resource Group (AVM)
│   │   ├── network/               # VNet + subnets (AVM)
│   │   ├── storage/               # Storage account, blobs, file shares (AVM)
│   │   ├── aks/                   # AKS cluster (AVM)
│   │   └── key-vault/             # Key Vault + ESO identity + federated creds
│   ├── ansible/
│   │   └── aks-config/            # Namespaces, storage classes, ClusterSecretStore
│   └── helmfile/
│       ├── external-secrets/      # External Secrets Operator
│       ├── ingress/               # NGINX Ingress Controller
│       └── demo-app/              # Demo microservices
├── apps/
│   └── demo-microservices/        # Helm chart (API, worker, Redis)
└── scripts/
    └── bootstrap-state.sh         # Azure state backend bootstrap
```

## Modules Used

| Module | Source | Purpose |
|--------|--------|---------|
| terraform-null-label | `cloudposse/label/null` | Consistent naming and tagging |
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | Resource group |
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` | VNet and subnets |
| Storage Account | `Azure/avm-res-storage-storageaccount/azurerm` | Blob + file storage |
| AKS | `Azure/avm-res-containerservice-managedcluster/azurerm` | Kubernetes cluster |
| Key Vault | `azurerm_key_vault` (native) | Secret storage for ESO |

## Workflows

| Workflow | Command | Description |
|----------|---------|-------------|
| `bootstrap` | `atmos workflow bootstrap` | One-time state backend setup |
| `infra` | `atmos workflow infra -s <stage>` | Deploy all infrastructure |
| `configure` | `atmos workflow configure -s <stage>` | Configure AKS (Ansible) |
| `deploy` | `atmos workflow deploy -s <stage>` | Deploy workloads (Helmfile) |
| `full` | `atmos workflow full -s <stage>` | All of the above in sequence |
| `infra-plan` | `atmos workflow infra-plan -s <stage>` | Dry run for infrastructure |
| `destroy` | `atmos workflow destroy -s <stage>` | Tear down everything |

## Environments

- **dev** - Smaller instances (Standard_B2s), single replicas, LRS storage, purge protection off
- **prod** - Larger instances (Standard_D2s_v5/D4s_v5), multiple replicas, GRS storage, purge protection on

## Secrets Management

Secrets flow: **Azure Key Vault** -> **External Secrets Operator** -> **Kubernetes Secrets** -> **Pods**

- No secrets in git, stack YAML, or Terraform state
- ESO authenticates to Key Vault via AKS workload identity (no stored credentials)
- Secrets auto-refresh on a configurable interval (default: 1h)
- Apps consume standard Kubernetes Secrets with no Azure SDK dependency
