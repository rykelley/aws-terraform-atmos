---
name: ansible-aks
description: >-
  Create Ansible playbooks for configuring AKS clusters including namespaces,
  StorageClasses, CSI drivers, and Kubernetes CRDs. Use when working with
  Ansible playbooks, AKS cluster configuration, site.yml, Kubernetes
  namespaces, StorageClasses, or ClusterSecretStore resources.
---

# Ansible for AKS Configuration

## Component Structure

```
components/ansible/{name}/
├── site.yml            # Main playbook
└── requirements.yml    # Ansible Galaxy collections
```

## Playbook Pattern

Playbooks target `localhost` and use `kubernetes.core` collection:

```yaml
---
- name: Configure AKS Cluster
  hosts: localhost
  connection: local
  gather_facts: false

  collections:
    - kubernetes.core

  vars:
    kubeconfig_path: "{{ kube_config_path | default('~/.kube/config') }}"

  tasks:
    - name: Create namespaces
      kubernetes.core.k8s:
        state: present
        kubeconfig: "{{ kubeconfig_path }}"
        definition:
          apiVersion: v1
          kind: Namespace
          metadata:
            name: "{{ item }}"
      loop: "{{ namespaces }}"
```

## Requirements

Always include `kubernetes.core`:

```yaml
collections:
  - name: kubernetes.core
    version: ">=3.0.0"
```

Install with: `ansible-galaxy collection install -r requirements.yml`

## Common Tasks

### StorageClass for Azure Files CSI

```yaml
- name: Create Azure Files StorageClass
  kubernetes.core.k8s:
    state: present
    kubeconfig: "{{ kubeconfig_path }}"
    definition:
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
        name: azure-files-csi
      provisioner: file.csi.azure.com
      parameters:
        skuName: Standard_LRS
      mountOptions:
        - dir_mode=0777
        - file_mode=0777
      reclaimPolicy: Delete
      volumeBindingMode: Immediate
```

### ClusterSecretStore for ESO

```yaml
- name: Create ClusterSecretStore for Key Vault
  kubernetes.core.k8s:
    state: present
    kubeconfig: "{{ kubeconfig_path }}"
    definition:
      apiVersion: external-secrets.io/v1beta1
      kind: ClusterSecretStore
      metadata:
        name: azure-key-vault
      spec:
        provider:
          azurekv:
            authType: WorkloadIdentity
            vaultUrl: "{{ key_vault_uri }}"
            serviceAccountRef:
              name: "{{ eso_service_account_name }}"
              namespace: external-secrets
```

## Atmos Integration

Variables flow from Atmos stacks to Ansible via `vars:`:

```yaml
# stacks/catalog/ansible/aks-config.yaml
components:
  ansible:
    aks-config:
      vars:
        namespaces:
          - demo-app
          - ingress
```

Run with: `atmos ansible playbook aks-config --stack {stage}`
