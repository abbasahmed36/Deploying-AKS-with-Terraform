variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "subnets" {
  description = <<EOT
   Map of subnets to create. Keys are your logical names (e.g. "system-pool", "user-pool").
   Each value sets the Azure subnet name and prefixes.
   EOT
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
