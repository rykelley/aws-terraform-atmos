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

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  name     = module.label.id
  location = var.region
  tags     = module.label.tags
}
