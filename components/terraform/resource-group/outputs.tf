output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group"
}

output "resource_group_id" {
  value       = module.resource_group.resource_id
  description = "ID of the resource group"
}

output "resource_group_location" {
  value       = var.region
  description = "Location of the resource group"
}

output "label_context" {
  value       = module.label.context
  description = "Label context for downstream modules"
}
