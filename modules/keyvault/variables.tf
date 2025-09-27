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
variable "terraform_principal_object_id" {
  type        = string
  description ="Object ID of the principal executing Terraform (user, service principal, or managed identity)"
  default     = null
}

