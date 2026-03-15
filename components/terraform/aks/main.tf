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

data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.namespace}-${var.environment}-${var.stage}-rg"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${module.label.id}-logs"
  location            = var.region
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = module.label.tags
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.5"

  name      = module.label.id
  parent_id = data.azurerm_resource_group.this.id
  location  = var.region

  kubernetes_version = var.kubernetes_version
  dns_prefix         = replace(module.label.id, "/[^a-zA-Z0-9-]/", "")

  default_agent_pool = {
    name            = "system"
    vm_size         = var.system_node_vm_size
    count_of        = var.system_node_count
    os_disk_size_gb = var.system_node_os_disk_size_gb
    vnet_subnet_id  = var.aks_subnet_id != "" ? var.aks_subnet_id : null
    mode            = "System"

    upgrade_settings = {
      max_surge = "33%"
    }
  }

  agent_pools = var.user_node_count > 0 ? {
    user = {
      name            = "user"
      vm_size         = var.user_node_vm_size
      count_of        = var.user_node_count
      os_disk_size_gb = var.user_node_os_disk_size_gb
      vnet_subnet_id  = var.aks_subnet_id != "" ? var.aks_subnet_id : null
      mode            = "User"

      upgrade_settings = {
        max_surge = "33%"
      }
    }
  } : {}

  managed_identities = {
    system_assigned = true
  }

  aad_profile = {
    enable_azure_rbac     = var.rbac_enabled
    tenant_id             = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = []
    managed               = true
  }

  oidc_issuer_profile = {
    enabled = var.oidc_issuer_enabled
  }

  security_profile = {
    workload_identity = {
      enabled = var.workload_identity_enabled
    }
  }

  network_profile = {
    network_plugin = "azure"
  }

  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }

  sku = {
    name = "Base"
    tier = "Free"
  }

  tags = module.label.tags
}

resource "azurerm_role_assignment" "aks_storage_blob_contributor" {
  count                = var.storage_account_name != "" ? 1 : 0
  scope                = data.azurerm_storage_account.this[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks.identity_principal_id
}

resource "azurerm_role_assignment" "aks_storage_file_contributor" {
  count                = var.storage_account_name != "" ? 1 : 0
  scope                = data.azurerm_storage_account.this[0].id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = module.aks.identity_principal_id
}

data "azurerm_storage_account" "this" {
  count               = var.storage_account_name != "" ? 1 : 0
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  count                = var.key_vault_id != "" ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.identity_principal_id
}
