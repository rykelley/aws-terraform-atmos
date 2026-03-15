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

module "storage_account_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  name                = "st"
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

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.namespace}-${var.environment}-${var.stage}-rg"

  containers = {
    for c in var.blob_containers : c.name => {
      name                  = c.name
      container_access_type = c.access_type
    }
  }

  shares = {
    for s in var.file_shares : s.name => {
      name  = s.name
      quota = s.quota
    }
  }
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6"

  name                     = module.storage_account_label.id
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = var.region
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  containers = local.containers
  shares     = local.shares

  tags = module.label.tags
}
