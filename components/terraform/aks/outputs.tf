output "cluster_id" {
  value       = module.aks.resource_id
  description = "AKS cluster resource ID"
}

output "cluster_name" {
  value       = module.aks.name
  description = "AKS cluster name"
}

output "cluster_fqdn" {
  value       = module.aks.resource.fqdn
  description = "AKS cluster FQDN"
}

output "kube_config_raw" {
  value       = module.aks.resource.kube_config_raw
  sensitive   = true
  description = "Raw kubeconfig for the AKS cluster"
}

output "kube_admin_config_raw" {
  value       = module.aks.resource.kube_admin_config_raw
  sensitive   = true
  description = "Raw admin kubeconfig for the AKS cluster"
}

output "cluster_identity_principal_id" {
  value       = module.aks.cluster_identity.principal_id
  description = "Principal ID of the AKS managed identity"
}

output "oidc_issuer_url" {
  value       = module.aks.resource.oidc_issuer_url
  description = "OIDC issuer URL for workload identity"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.this.id
  description = "Log Analytics workspace ID"
}
