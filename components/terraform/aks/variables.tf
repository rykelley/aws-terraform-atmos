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
  default     = "aks"
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

variable "aks_subnet_id" {
  type        = string
  default     = ""
  description = "Subnet ID for AKS nodes. Pass from network component output."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.30"
  description = "Kubernetes version for AKS"
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = true
  description = "Enable OIDC issuer for workload identity"
}

variable "workload_identity_enabled" {
  type        = bool
  default     = true
  description = "Enable workload identity"
}

variable "system_node_count" {
  type        = number
  default     = 2
  description = "Number of nodes in the system node pool"
}

variable "system_node_vm_size" {
  type        = string
  default     = "Standard_D2s_v5"
  description = "VM size for system nodes"
}

variable "system_node_os_disk_size_gb" {
  type        = number
  default     = 50
  description = "OS disk size in GB for system nodes"
}

variable "user_node_count" {
  type        = number
  default     = 2
  description = "Number of nodes in the user node pool"
}

variable "user_node_vm_size" {
  type        = string
  default     = "Standard_D4s_v5"
  description = "VM size for user nodes"
}

variable "user_node_os_disk_size_gb" {
  type        = number
  default     = 100
  description = "OS disk size in GB for user nodes"
}

variable "storage_account_name" {
  type        = string
  default     = ""
  description = "Name of the storage account for role assignments"
}

variable "key_vault_id" {
  type        = string
  default     = ""
  description = "Key Vault resource ID for AKS identity role assignments"
}

variable "tenant" {
  type        = string
  default     = null
  description = "Tenant identifier (passed from Atmos, unused in this component)"
}

variable "label_order" {
  type        = list(string)
  default     = ["namespace", "environment", "stage", "name", "attributes"]
  description = "Label field order for terraform-null-label"
}

variable "regex_replace_chars" {
  type        = string
  default     = "/[^a-zA-Z0-9-]/"
  description = "Regex to replace unwanted chars in labels"
}
