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
  default     = "storage"
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

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Storage account tier"
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Storage replication type (LRS, GRS, ZRS, GZRS)"
}

variable "blob_containers" {
  type = list(object({
    name        = string
    access_type = optional(string, "private")
  }))
  default     = []
  description = "List of blob containers to create"
}

variable "file_shares" {
  type = list(object({
    name  = string
    quota = optional(number, 50)
  }))
  default     = []
  description = "List of file shares to create"
}
