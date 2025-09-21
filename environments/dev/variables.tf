############################################
# Core
############################################
variable "location" {
  type    = string
  default = "swedencentral"
}

variable "prefix" {
  type    = string
  default = "aksbl"
}

# null =  AKS choose the latest supported version in the region
variable "kubernetes_version" {
  type    = string
  default = null
}

############################################
# Networking (VNet & Subnet for AKS nodes)
############################################
variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

#variable "aks_subnet_cidr" {
#  type    = string
#  default = "10.10.0.0/22"
#}

variable "system_subnet_cidr" {
  type = string
}

variable "user_subnet_cidr" {
  type = string
}

variable "privendpoint_subnet_cidr" {
  type = string
}

############################################
# AKS in-cluster networking (cluster IPs)
############################################
# Cluster DNS service IP (must be within service_cidr)
variable "dns_service_ip" {
  type    = string
  default = "10.2.0.10"
}

# Cluster services CIDR (non-overlapping with VNet)
variable "service_cidr" {
  type    = string
  default = "10.2.0.0/24"
}

############################################
# Node pool sizing
############################################
variable "system_vm_size" {
  type    = string
  default = "Standard_D2as_v5"
}

variable "system_node_count" {
  type    = number
  default = 1
}

# Whether to create the optional user pool
variable "create_user_pool" {
  type    = bool
  default = false
}

variable "user_vm_size" {
  type    = string
  default = "Standard_D2as_v5"
}

variable "user_node_count" {
  type    = number
  default = 1
}

############################################
# API server access (for PUBLIC API scenarios)
############################################
# Example: Lock  your IP: ["203.0.113.5/32"]
variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}

############################################
# AKS SKU tier
############################################
variable "sku_tier" {
  type    = string
  default = "Free"
}

############################################
# Logs retention (Log Analytics workspaces)
############################################
variable "logs_retention" {
  type    = number
  default = 30
}

############################################
# Tags
############################################
variable "tags" {
  type    = map(string)
  default = { env = "dev" }
}

############################################
# Workload Identity + Key Vault (per app)
############################################
variable "wi_namespace" {
  type = string
}

variable "wi_service_account" {
  type = string
}

# Existing Key Vault name to read secrets from
variable "kv_name" {
  type = string
}


