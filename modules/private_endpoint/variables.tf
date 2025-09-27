variable "name" {
 type = string
}

variable "location"{
 type = string
}

variable "resource_group_name"   {
 type = string
}

# Subnet where the private endpoint NIC will live
variable "subnet_id" {
 type = string
}

#variable "privendpoint_subnet_cidr" {
#  type = string
#}


# The target resource to expose privately (like  Key Vault ID, ACR ID)
variable "target_resource_id"    {
 type = string
}

# The subresource(s) to connect (service-specific)
# Examples:
#   Key Vault: ["vault"]
#   ACR: ["registry","registry_data"]

variable "subresource_names"{
    type = list(string)
}

variable "private_dns_zone_names" {
  type = list(string)
}

# The VNet that must resolve private names (usually your AKS VNet)
variable "vnet_id" {
 type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}


