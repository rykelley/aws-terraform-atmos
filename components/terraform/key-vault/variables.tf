variable "namespace" {
  type        = string
  description = "Namespace for naming convention"
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g., ue2)"
}

variable "stage" {
  type        = string
  description = "Stage (e.g., dev, prod)"
}

variable "name" {
  type        = string
  default     = "kv"
  description = "Component name"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes for naming"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter for label ID"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags"
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "Resource group name. If empty, derived from naming convention."
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "Key Vault SKU (standard or premium)"
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Days to retain soft-deleted vaults"
}

variable "purge_protection_enabled" {
  type        = bool
  default     = false
  description = "Enable purge protection (set true for prod)"
}

variable "aks_oidc_issuer_url" {
  type        = string
  default     = ""
  description = "AKS OIDC issuer URL for federated credentials"
}

variable "eso_service_account_name" {
  type        = string
  default     = "external-secrets-sa"
  description = "Kubernetes ServiceAccount name used by ESO"
}

variable "eso_service_account_namespace" {
  type        = string
  default     = "external-secrets"
  description = "Kubernetes namespace where ESO runs"
}

variable "storage_account_name" {
  type        = string
  default     = ""
  description = "Storage account name to store as a Key Vault secret"
}

variable "storage_account_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Storage account key to store as a Key Vault secret"
}

variable "additional_secrets" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Additional secrets to store in Key Vault (name => value)"
}
