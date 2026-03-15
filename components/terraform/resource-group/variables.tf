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
  default     = "rg"
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
