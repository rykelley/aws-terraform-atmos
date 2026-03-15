output "vnet_id" {
  value       = module.vnet.resource_id
  description = "ID of the virtual network"
}

output "vnet_name" {
  value       = module.vnet.name
  description = "Name of the virtual network"
}

output "aks_subnet_id" {
  value       = module.vnet.subnets["aks"].resource_id
  description = "ID of the AKS subnet"
}
