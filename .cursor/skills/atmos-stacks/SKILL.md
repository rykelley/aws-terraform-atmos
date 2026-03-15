---
name: atmos-stacks
description: >-
  Create and manage Atmos stacks, catalogs, imports, and workflows for
  orchestrating Terraform, Ansible, and Helmfile components. Use when working
  with atmos.yaml, stacks/, workflows, or when the user mentions Atmos,
  stack configuration, catalog entries, or deployment orchestration.
---

# Atmos Stacks

## Project Layout

```
atmos.yaml                         # CLI config: base paths, backend, naming
stacks/
  orgs/homelab/_defaults.yaml      # Org-wide defaults (namespace, tags, backend)
  catalog/
    terraform/{component}.yaml     # Terraform component defaults
    ansible/{component}.yaml       # Ansible component defaults
    helmfile/{component}.yaml      # Helmfile component defaults
  deploy/
    {stage}/{stack}.yaml           # Environment stacks (dev, prod)
  workflows/
    deploy.yaml                    # Orchestration workflows
components/
  terraform/{component}/           # Terraform root modules
  ansible/{component}/             # Ansible playbooks
  helmfile/{component}/            # Helmfile releases
```

## Key Conventions

### Naming via Cloud Posse Label

All stacks inherit these vars from `_defaults.yaml`:

```yaml
vars:
  namespace: homelab
  delimiter: "-"
  label_order: [namespace, environment, stage, name, attributes]
```

Resources are named `{namespace}-{environment}-{stage}-{name}`, e.g. `homelab-ue2-prod-aks`.

### Backend Auto-Generation

`atmos.yaml` sets `auto_generate_backend_file: true`. The backend key uses
template interpolation:

```yaml
key: "terraform/{{ .component }}/{{ .vars.stage }}.tfstate"
```

### Stack Inheritance

Environment stacks import org defaults + catalog entries:

```yaml
import:
  - orgs/homelab/_defaults
  - catalog/terraform/resource-group
  - catalog/terraform/network
```

Then override only what differs per environment under `components:`.

## Adding a New Terraform Component

1. Create catalog entry at `stacks/catalog/terraform/{name}.yaml`:

```yaml
components:
  terraform:
    {name}:
      vars:
        # component defaults
```

2. Add `- catalog/terraform/{name}` to imports in each `stacks/deploy/{stage}/*.yaml`
3. Add environment-specific overrides under `components.terraform.{name}.vars`
4. Add `terraform apply {name}` step to relevant workflows in `stacks/workflows/deploy.yaml`

## Adding a New Helmfile Component

1. Create catalog at `stacks/catalog/helmfile/{name}.yaml`
2. Import in deploy stacks
3. Add `helmfile apply {name}` to workflow steps

## Workflows

Workflows live in `stacks/workflows/deploy.yaml` and chain Atmos commands:

```yaml
workflows:
  infra:
    steps:
      - command: terraform apply resource-group -auto-approve
      - command: terraform apply network -auto-approve
```

Run with: `atmos workflow infra -f deploy --stack prod`

## Common Commands

```bash
atmos terraform plan {component} --stack {stage}
atmos terraform apply {component} --stack {stage}
atmos helmfile apply {component} --stack {stage}
atmos workflow {name} -f deploy --stack {stage}
atmos describe component {component} --stack {stage}
```
