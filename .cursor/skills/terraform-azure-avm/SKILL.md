---
name: terraform-azure-avm
description: >-
  Create Terraform components using Azure Verified Modules (AVM) and Cloud
  Posse terraform-null-label for consistent naming and tagging. Use when
  creating or editing Terraform modules, Azure infrastructure, AVM modules,
  .tf files, or when the user mentions Terraform, Azure resources, or
  infrastructure components.
---

# Terraform with Azure Verified Modules

## Component Structure

Every Terraform component lives in `components/terraform/{name}/` with four files:

```
components/terraform/{name}/
├── main.tf        # Resources and module calls
├── variables.tf   # Input variables
├── outputs.tf     # Output values
└── versions.tf    # Provider and terraform version constraints
```

## Required Pattern: Cloud Posse Label

Every component MUST include the `cloudposse/label/null` module as the first
block in `main.tf`:

```hcl
module "label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  name        = var.name
  attributes  = var.attributes
  delimiter   = var.delimiter
  tags        = var.tags
}
```

Use `module.label.id` for resource names and `module.label.tags` for tags.

### Azure Naming Constraints

Some Azure resources have strict naming rules. Create a secondary label when needed:

```hcl
module "sa_label" {
  source              = "cloudposse/label/null"
  version             = "~> 0.25"
  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  name                = "sa"
  id_length_limit     = 24
  label_value_case    = "lower"
  delimiter           = ""
  regex_replace_chars = "/[^a-z0-9]/"
  tags                = var.tags
}
```

Key constraints:
- **Storage Accounts**: max 24 chars, lowercase alphanumeric only
- **Key Vaults**: max 24 chars, alphanumeric and hyphens

## Required Variables (variables.tf)

Every component must declare these (inherited from Atmos stacks):

```hcl
variable "namespace"   { type = string }
variable "environment" { type = string }
variable "stage"       { type = string }
variable "name"        { type = string }
variable "attributes"  { type = list(string); default = [] }
variable "delimiter"   { type = string; default = "-" }
variable "tags"        { type = map(string); default = {} }
variable "region"      { type = string }
```

## Provider Configuration (versions.tf)

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

## AVM Module Pattern

Use Azure Verified Modules from the `Azure/` GitHub org:

```hcl
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  name     = module.label.id
  location = var.region
  tags     = module.label.tags
}
```

AVM module naming: `Azure/avm-res-{provider}-{resource}/azurerm`

Browse available modules: https://github.com/Azure/Azure-Verified-Modules

## Cross-Component References

Components reference each other's outputs via data sources or variable
passthrough from Atmos stacks. Use `data` blocks for resources created by
other components:

```hcl
data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}
```

## Outputs (outputs.tf)

Export values other components or Helmfile/Ansible will need:

```hcl
output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group"
}
```
