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
  default     = "tfstate"
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
