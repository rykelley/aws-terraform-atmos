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

module "aks_subnet_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["aks"]
  context    = module.label.context
}

data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.namespace}-${var.environment}-${var.stage}-rg"
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.7"

  name          = module.label.id
  parent_id     = data.azurerm_resource_group.this.id
  location      = var.region
  address_space = var.vnet_address_space
  tags          = module.label.tags

  subnets = {
    aks = {
      name             = module.aks_subnet_label.id
      address_prefixes = [var.aks_subnet_prefix]
    }
  }
}
