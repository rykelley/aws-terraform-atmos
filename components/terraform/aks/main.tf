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

  name                = module.label.id
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.region

  kubernetes_version = var.kubernetes_version

  default_node_pool = {
    name                = "system"
    vm_size             = var.system_node_vm_size
    node_count          = var.system_node_count
    os_disk_size_gb     = var.system_node_os_disk_size_gb
    vnet_subnet_id      = var.aks_subnet_id != "" ? var.aks_subnet_id : null
    enable_auto_scaling = false

    upgrade_settings = {
      max_surge = "33%"
    }
  }

  node_pools = {
    user = {
      name                = "user"
      vm_size             = var.user_node_vm_size
      node_count          = var.user_node_count
      os_disk_size_gb     = var.user_node_os_disk_size_gb
      vnet_subnet_id      = var.aks_subnet_id != "" ? var.aks_subnet_id : null
      enable_auto_scaling = false
      mode                = "User"

      upgrade_settings = {
        max_surge = "33%"
      }
    }
  }

  role_based_access_control_enabled = var.rbac_enabled
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  workload_identity_enabled         = var.workload_identity_enabled

  identity = {
    type = "SystemAssigned"
  }

  network_profile = {
    network_plugin = "azure"
    network_policy = "azure"
  }

  oms_agent = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  tags = module.label.tags
}

resource "azurerm_role_assignment" "aks_storage_blob_contributor" {
  count                = var.storage_account_name != "" ? 1 : 0
  scope                = data.azurerm_storage_account.this[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks.cluster_identity.principal_id
}

resource "azurerm_role_assignment" "aks_storage_file_contributor" {
  count                = var.storage_account_name != "" ? 1 : 0
  scope                = data.azurerm_storage_account.this[0].id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = module.aks.cluster_identity.principal_id
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
  principal_id         = module.aks.cluster_identity.principal_id
}
