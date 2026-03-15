output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault resource ID"
}

output "key_vault_name" {
  value       = azurerm_key_vault.this.name
  description = "Key Vault name"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "Key Vault URI"
}

output "eso_identity_client_id" {
  value       = azurerm_user_assigned_identity.eso.client_id
  description = "Client ID of the ESO managed identity"
}

output "eso_identity_principal_id" {
  value       = azurerm_user_assigned_identity.eso.principal_id
  description = "Principal ID of the ESO managed identity"
}

output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure AD tenant ID"
}
