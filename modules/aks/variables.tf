variable "name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

# Networking
variable "subnet_id" {
  type = string
}

variable "dns_service_ip" {
  type = string
}

variable "service_cidr" {
  type = string
}

# Log Analytics

variable "la_workspace_id" {
  type = string
} # for Container Insights

variable "la_audit_workspace_id" {
  type = string
} # for control-plane/audit logs

# ACR
variable "acr_id" {
  type = string
}

# Node pools
variable "system_vm_size" {
  type    = string
  default = "Standard_D4ds_v4"
}

variable "system_node_count" {
  type    = number
  default = 2
}

variable "user_vm_size" {
  type    = string
  default = "Standard_D4ds_v4"
}

variable "user_node_count" {
  type    = number
  default = 1
}

variable "create_user_pool" {
  type    = bool
  default = false
}

# API allow
variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}

# Tags 
variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku_tier" {
  type    = string
  default = "Free"
} 

variable "enable_acr_role_assignment" {
  type    = bool
  default = true
}
