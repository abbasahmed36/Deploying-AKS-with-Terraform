terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }

    random = {
      source  = "hashicorp/random",
      version = "~> 3.6"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}


resource "random_string" "sfx" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.account_name}${random_string.sfx.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}



resource "azurerm_storage_container" "c" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "local_file" "backend" {
  filename = "${path.module}/backend.hcl"
  content  = <<-HCL
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    storage_account_name = "${azurerm_storage_account.sa.name}"   
    container_name       = "${azurerm_storage_container.c.name}"
    key                  = "${var.key}"
  HCL
}
