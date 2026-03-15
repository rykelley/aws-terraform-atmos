# Training Plan: Atmos vs Traditional Terraform and Ansible

This guide walks through why Atmos exists, how it compares to using Terraform and Ansible directly, and how to work with it in this project. Each section builds on the last. Work through them in order.

---

## Part 1: The Problem Atmos Solves

### What happens without Atmos

When you manage infrastructure with plain Terraform and Ansible, you typically end up with:

**Duplicated Terraform root modules per environment:**

```
terraform/
├── dev/
│   ├── main.tf          # copy of prod/main.tf with different values
│   ├── variables.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf          # another copy
│   ├── variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars
```

Problems with this approach:

- **Code duplication** -- the same `main.tf` is copied 3 times, only the `.tfvars` differ
- **Drift** -- someone updates dev but forgets to update prod, and they diverge
- **No inheritance** -- common settings (provider config, backend, tags) are repeated everywhere
- **Bash glue** -- you write wrapper scripts to run `terraform apply` in the right directory with the right vars
- **No orchestration** -- Terraform cannot call Ansible or Helmfile, so you chain them manually

**Scattered Ansible inventory and playbooks:**

```
ansible/
├── inventory/
│   ├── dev.ini
│   ├── staging.ini
│   └── prod.ini
├── playbooks/
│   └── configure-cluster.yml
└── group_vars/
    ├── dev.yml
    ├── staging.yml
    └── prod.yml
```

Problems:

- Variables live in a completely separate system from Terraform
- No single source of truth for "what is deployed where"
- You have to manually keep Terraform outputs and Ansible vars in sync

### What Atmos does differently

Atmos separates **what** (components) from **where** (stacks):

```
components/           # "what" -- write each module once
├── terraform/
│   ├── aks/          # one AKS module, used by all environments
│   └── storage/      # one storage module, used by all environments
├── ansible/
│   └── aks-config/   # one playbook, parameterized
└── helmfile/
    └── ingress/      # one helmfile, parameterized

stacks/               # "where" -- configure per environment
├── deploy/
│   ├── dev/aks.yaml  # dev-specific values (small VMs, 1 replica)
│   └── prod/aks.yaml # prod-specific values (large VMs, 2 replicas)
```

**One component, many environments.** The Terraform code is written once. Each environment is just a YAML file that sets different variable values. No duplication.

---

## Part 2: Side-by-Side Comparison

### Deploying infrastructure

**Traditional Terraform:**

```bash
cd terraform/prod
terraform init -backend-config=prod.hcl
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

You have to know:
- Which directory to `cd` into
- Which backend config to use
- Which var file to pass
- You repeat this for every module (network, aks, storage...)

**With Atmos:**

```bash
atmos terraform apply aks -s prod
```

Atmos knows:
- Where the component lives (from `atmos.yaml`)
- Which backend to use (from the stack's `terraform.backend` config)
- Which variables to pass (from the stack's `vars` section)
- All of this is resolved from YAML -- you just say "apply aks in prod"

### Configuring a cluster

**Traditional Ansible:**

```bash
ansible-playbook -i inventory/prod.ini playbooks/configure-cluster.yml \
  --extra-vars "@group_vars/prod.yml"
```

You have to know the inventory file, the var file, and keep them in sync with what Terraform provisioned.

**With Atmos:**

```bash
atmos ansible playbook aks-config -s prod
```

Atmos passes the stack's `vars` section to Ansible as `--extra-vars` automatically. The same YAML that configures Terraform also configures Ansible.

### Deploying workloads

**Traditional Helmfile:**

```bash
cd helmfile/prod
helmfile -e prod apply
```

**With Atmos:**

```bash
atmos helmfile apply ingress -s prod
```

Same pattern. Atmos injects stack vars into Helmfile's `.Values`.

### Running everything

**Traditional (bash script you have to write and maintain):**

```bash
#!/bin/bash
set -e
cd terraform/prod/resource-group && terraform apply -auto-approve
cd ../network && terraform apply -auto-approve
cd ../storage && terraform apply -auto-approve
cd ../aks && terraform apply -auto-approve
cd ../../ansible && ansible-playbook -i inventory/prod.ini playbooks/configure.yml
cd ../helmfile/prod && helmfile apply
```

**With Atmos (declarative workflow):**

```bash
atmos workflow full -s prod
```

The workflow is defined in YAML, not a bash script:

```yaml
workflows:
  full:
    steps:
      - command: terraform apply resource-group -auto-approve
      - command: terraform apply network -auto-approve
      - command: terraform apply storage -auto-approve
      - command: terraform apply aks -auto-approve
      - command: terraform apply key-vault -auto-approve
      - command: ansible playbook aks-config
      - command: helmfile apply external-secrets
      - command: helmfile apply ingress
      - command: helmfile apply demo-app
```

---

## Part 3: Key Atmos Concepts

### 3.1 Components

A component is a reusable unit of infrastructure. In this project:

| Component | Type | What it does |
|-----------|------|--------------|
| `resource-group` | Terraform | Creates an Azure resource group |
| `network` | Terraform | Creates VNet and subnets |
| `storage` | Terraform | Creates storage account, blobs, file shares |
| `aks` | Terraform | Creates the AKS cluster |
| `key-vault` | Terraform | Creates Key Vault, ESO identity, secrets |
| `aks-config` | Ansible | Configures namespaces, storage classes, ClusterSecretStore |
| `external-secrets` | Helmfile | Installs External Secrets Operator |
| `ingress` | Helmfile | Installs NGINX ingress controller |
| `demo-app` | Helmfile | Deploys the demo microservices |

Components live under `components/terraform/`, `components/ansible/`, and `components/helmfile/`. They are generic -- they accept variables but do not hardcode environment-specific values.

### 3.2 Stacks

A stack is a YAML file that maps components to an environment with specific configuration.

Look at `stacks/deploy/dev/aks.yaml`:

```yaml
vars:
  environment: ue2
  stage: dev
  region: eastus2

components:
  terraform:
    aks:
      vars:
        system_node_count: 1
        system_node_vm_size: Standard_B2s
```

And `stacks/deploy/prod/aks.yaml`:

```yaml
vars:
  environment: ue2
  stage: prod
  region: eastus2

components:
  terraform:
    aks:
      vars:
        system_node_count: 2
        system_node_vm_size: Standard_D2s_v5
```

Same AKS component. Different values. No code duplication.

### 3.3 Imports and Inheritance

Stacks can import from other files. This project uses a three-layer hierarchy:

```
stacks/orgs/homelab/_defaults.yaml    # org-wide: namespace, backend, tags
stacks/catalog/terraform/aks.yaml     # component defaults: k8s version, node sizes
stacks/deploy/prod/aks.yaml           # environment overrides: prod-specific values
```

Each layer overrides the one above it. The stack file imports them:

```yaml
import:
  - orgs/homelab/_defaults       # base settings
  - catalog/terraform/aks        # AKS defaults
```

This means:
- Backend config is defined once in `_defaults.yaml`, not per component
- Tags are defined once, inherited everywhere
- Component defaults are defined in catalogs, overridden per environment

### 3.4 Workflows

Workflows chain multiple commands together. Instead of remembering the deploy order, you run:

```bash
atmos workflow full -s prod
```

Workflows are defined in `stacks/workflows/deploy.yaml`. They reference Atmos commands, not shell commands.

### 3.5 Backend Auto-Generation

Atmos generates `backend.tf.json` for each Terraform component at runtime based on the stack's `terraform.backend` config. You never write backend blocks in your `.tf` files. The key uses Go templates:

```yaml
key: "terraform/{{ .component }}/{{ .vars.stage }}.tfstate"
```

This produces unique state file paths like `terraform/aks/prod.tfstate` automatically.

---

## Part 4: Benefits Summary

| Area | Without Atmos | With Atmos |
|------|--------------|------------|
| **Code duplication** | Copy Terraform modules per environment | Write once, configure per environment |
| **Variable management** | `.tfvars`, `group_vars`, helmfile envs -- all separate | Single YAML stack file for all tools |
| **Backend config** | Hardcoded per module or passed via `-backend-config` | Auto-generated from stack config |
| **Deploy orchestration** | Bash scripts chaining terraform, ansible, helm | Declarative YAML workflows |
| **Environment consistency** | Manual effort to keep dev/prod aligned | Inheritance ensures shared baseline |
| **Naming/tagging** | Ad-hoc, inconsistent across modules | `terraform-null-label` with vars from stacks |
| **Adding a new environment** | Copy directory tree, update all var files | Add one YAML file under `stacks/deploy/` |
| **Onboarding** | "Read the bash scripts to understand deploy order" | `atmos workflow full -s dev` |
| **Multi-tool** | Separate workflows for Terraform, Ansible, Helmfile | One tool, one CLI, one config format |

---

## Part 5: Hands-On Exercises

Work through these in order to build muscle memory with Atmos.

### Exercise 1: Explore what Atmos knows

```bash
# See all stacks and components Atmos can see
atmos describe stacks

# See the fully resolved config for AKS in dev
atmos describe component aks -s dev

# Compare dev vs prod
atmos describe component aks -s dev | head -30
atmos describe component aks -s prod | head -30
```

This shows you the merged result of all imports, defaults, and overrides.

### Exercise 2: Dry-run infrastructure

```bash
# Plan all infrastructure without applying
atmos workflow infra-plan -s dev

# Plan a single component
atmos terraform plan aks -s dev
```

Read the plan output. Notice how Atmos resolved the backend, variables, and provider config from the stack YAML.

### Exercise 3: Trace variable inheritance

Pick a variable like `namespace`. Trace where it comes from:

1. `stacks/orgs/homelab/_defaults.yaml` sets `namespace: homelab`
2. `stacks/catalog/terraform/aks.yaml` does not override it
3. `stacks/deploy/dev/aks.yaml` does not override it
4. The AKS component receives `namespace = "homelab"` and passes it to `terraform-null-label`

Now trace `system_node_vm_size`:

1. `_defaults.yaml` does not set it
2. `catalog/terraform/aks.yaml` sets default `Standard_D2s_v5`
3. `stacks/deploy/dev/aks.yaml` overrides to `Standard_B2s`
4. `stacks/deploy/prod/aks.yaml` keeps `Standard_D2s_v5`

### Exercise 4: Add a new environment

Create a staging environment:

1. Copy `stacks/deploy/dev/aks.yaml` to `stacks/deploy/staging/aks.yaml`
2. Change `stage: staging` and adjust VM sizes, replica counts
3. Run `atmos describe component aks -s staging` to verify
4. Run `atmos workflow infra-plan -s staging` to see the plan

Notice you did not copy any Terraform code. You only added YAML configuration.

### Exercise 5: Compare to doing it manually

Try deploying the resource group without Atmos:

```bash
cd components/terraform/resource-group
terraform init -backend-config="resource_group_name=tfstate-homelab" \
  -backend-config="storage_account_name=homelabue2tfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform/resource-group/dev.tfstate"
terraform plan -var="namespace=homelab" -var="environment=ue2" \
  -var="stage=dev" -var="name=rg" -var="region=eastus2" \
  -var='tags={"ManagedBy":"Atmos","Project":"homelab-aks"}'
```

Now compare:

```bash
atmos terraform plan resource-group -s dev
```

Same result. One command vs many flags.

### Exercise 6: Understand the secrets flow

Trace how a secret gets from Azure Key Vault to a pod:

1. `components/terraform/key-vault/main.tf` -- creates Key Vault, stores `storage-account-name` secret
2. `components/terraform/key-vault/main.tf` -- creates managed identity with federated credentials
3. `components/helmfile/external-secrets/helmfile.yaml` -- installs ESO with workload identity
4. `components/ansible/aks-config/site.yml` -- creates `ClusterSecretStore` pointing at Key Vault
5. `apps/demo-microservices/templates/external-secret.yaml` -- `ExternalSecret` syncs the secret
6. `apps/demo-microservices/templates/api-deployment.yaml` -- pod reads from Kubernetes Secret

All of these are orchestrated by `atmos workflow full -s dev` in the right order.

---

## Part 6: Common Operations Reference

| Task | Command |
|------|---------|
| Deploy everything | `atmos workflow full -s <stage>` |
| Plan without applying | `atmos workflow infra-plan -s <stage>` |
| Deploy single component | `atmos terraform apply aks -s <stage>` |
| Destroy everything | `atmos workflow destroy -s <stage>` |
| View resolved config | `atmos describe component <name> -s <stage>` |
| List all stacks | `atmos describe stacks` |
| Run Ansible playbook | `atmos ansible playbook aks-config -s <stage>` |
| Deploy Helm release | `atmos helmfile apply ingress -s <stage>` |
| View Atmos config | `atmos describe config` |

---

## Part 7: When to Use What

| Scenario | Tool | Reason |
|----------|------|--------|
| Create Azure resources (VMs, VNets, storage) | Terraform via Atmos | Declarative, state-tracked, AVM modules |
| Configure a Kubernetes cluster (namespaces, RBAC, CRDs) | Ansible via Atmos | Imperative tasks, good for one-time setup |
| Deploy applications into Kubernetes | Helmfile via Atmos | Helm chart management, release lifecycle |
| Chain all of the above in order | Atmos Workflows | Single command, repeatable, documented |
| Add a new environment | Stack YAML | No code changes, just configuration |
| Change a resource across all environments | Component `.tf` file | One change, applied everywhere |
| Change a setting for one environment | Stack YAML override | Override just the value you need |

---

## Further Reading

- [Atmos Documentation](https://atmos.tools/)
- [Atmos Core Concepts: Stacks](https://atmos.tools/core-concepts/stacks)
- [Atmos Core Concepts: Components](https://atmos.tools/core-concepts/components)
- [Atmos Workflows](https://atmos.tools/core-concepts/workflows)
- [Atmos Ansible Components](https://atmos.tools/stacks/components/ansible)
- [Atmos Helmfile Components](https://atmos.tools/stacks/components/helmfile)
- [Atmos Backend Configuration](https://atmos.tools/stacks/backend)
- [Cloud Posse terraform-null-label](https://github.com/cloudposse/terraform-null-label)
- [External Secrets Operator](https://external-secrets.io/)
