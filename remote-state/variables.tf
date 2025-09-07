variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "account_name" {
  type = string
}

variable "container_name" {
  type    = string
  default = "tfstate"
}

variable "key" {
  type = string
}
