output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "Name of the Terraform state resource group"
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Name of the Terraform state storage account"
}

output "container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "Name of the Terraform state container"
}
