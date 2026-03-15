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
  default     = "vnet"
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
  description = "Resource group name. If empty, derived from Atmos remote state."
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for the VNet"
}

variable "aks_subnet_prefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR for the AKS node subnet"
}
