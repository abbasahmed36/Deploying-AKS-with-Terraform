variable "kv_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "create_seed_secret" {
  type    = bool
  default = false
}

variable "seed_secret_name" {
  type    = string
  default = "my-secret"
}

variable "seed_secret_value" {
  type      = string
  default   = null
  sensitive = true
}

