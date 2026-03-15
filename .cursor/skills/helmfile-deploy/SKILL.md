---
name: helmfile-deploy
description: >-
  Create Helmfile components for deploying Helm charts to AKS via Atmos.
  Use when working with Helmfile, helmfile.yaml, Helm chart deployments,
  Kubernetes workloads, ingress controllers, or when deploying applications
  to AKS clusters.
---

# Helmfile Deployments

## Component Structure

```
components/helmfile/{name}/
└── helmfile.yaml
```

## Helmfile Template

```yaml
repositories:
  - name: {repo-name}
    url: https://charts.example.io

releases:
  - name: {release-name}
    namespace: {namespace}
    chart: {repo-name}/{chart-name}
    version: "{{ .Values.chart_version | default \"1.0.0\" }}"
    createNamespace: true
    wait: true
    timeout: 300
    values:
      - key: value
```

## Atmos Variable Interpolation

Helmfile accesses Atmos stack variables via `.Values`:

```yaml
version: "{{ .Values.chart_version | default \"0.10.7\" }}"
```

Variables are defined in catalog and overridden in deploy stacks:

```yaml
# stacks/catalog/helmfile/external-secrets.yaml
components:
  helmfile:
    external-secrets:
      vars:
        chart_version: "0.10.7"
```

## Resource Limits

Always set resource requests and limits:

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi
```

## Workload Identity Annotations

For pods needing Azure identity (like ESO):

```yaml
serviceAccount:
  annotations:
    azure.workload.identity/client-id: "{{ .Values.eso_identity_client_id }}"
podLabels:
  azure.workload.identity/use: "true"
```

## Adding a New Helmfile Component

1. Create `components/helmfile/{name}/helmfile.yaml`
2. Create catalog: `stacks/catalog/helmfile/{name}.yaml`
3. Import catalog in deploy stacks: `- catalog/helmfile/{name}`
4. Add overrides under `components.helmfile.{name}.vars`
5. Add `helmfile apply {name}` to workflow in `stacks/workflows/deploy.yaml`
6. Run: `atmos helmfile apply {name} --stack {stage}`
