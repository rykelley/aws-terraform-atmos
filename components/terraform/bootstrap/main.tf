module "label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  name        = "tfstate"
  attributes  = var.attributes
  delimiter   = var.delimiter
  tags        = var.tags
}

module "storage_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  name                = "st"
  attributes          = ["tfstate"]
  id_length_limit     = 24
  label_value_case    = "lower"
  delimiter           = ""
  regex_replace_chars = "/[^a-z0-9]/"
  tags                = var.tags
}

resource "azurerm_resource_group" "tfstate" {
  name     = module.label.id
  location = var.region
  tags     = module.label.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = module.storage_label.id
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = module.label.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
