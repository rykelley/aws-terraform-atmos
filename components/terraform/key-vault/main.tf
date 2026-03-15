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

module "kv_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  name                = "kv"
  attributes          = var.attributes
  id_length_limit     = 24
  label_value_case    = "lower"
  delimiter           = ""
  regex_replace_chars = "/[^a-z0-9]/"
  tags                = var.tags
}

data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.namespace}-${var.environment}-${var.stage}-rg"

  secret_names = concat(
    var.storage_account_name != "" ? ["storage-account-name", "storage-account-key"] : [],
    keys(nonsensitive(var.additional_secrets))
  )

  secret_values = merge(
    var.storage_account_name != "" ? {
      "storage-account-name" = var.storage_account_name
      "storage-account-key"  = var.storage_account_key
    } : {},
    var.additional_secrets
  )
}

resource "azurerm_key_vault" "this" {
  name                       = module.kv_label.id
  location                   = var.region
  resource_group_name        = data.azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  enable_rbac_authorization  = true

  tags = module.label.tags
}

resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each = toset(local.secret_names)

  name         = each.value
  value        = local.secret_values[each.value]
  key_vault_id = azurerm_key_vault.this.id
  tags         = module.label.tags

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_user_assigned_identity" "eso" {
  name                = "${module.label.id}-eso"
  location            = var.region
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = module.label.tags
}

resource "azurerm_role_assignment" "eso_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.eso.principal_id
}

resource "azurerm_federated_identity_credential" "eso" {
  count = var.aks_oidc_issuer_url != "" ? 1 : 0

  name                = "eso-federated-credential"
  resource_group_name = data.azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.eso.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:${var.eso_service_account_namespace}:${var.eso_service_account_name}"
}
