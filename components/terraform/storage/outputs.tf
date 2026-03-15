output "storage_account_id" {
  value       = module.storage_account.resource_id
  description = "ID of the storage account"
}

output "storage_account_name" {
  value       = module.storage_account_label.id
  description = "Name of the storage account"
}

output "primary_blob_endpoint" {
  value       = module.storage_account.resource.primary_blob_endpoint
  sensitive   = true
  description = "Primary blob endpoint"
}

output "primary_file_endpoint" {
  value       = module.storage_account.resource.primary_file_endpoint
  sensitive   = true
  description = "Primary file endpoint"
}
