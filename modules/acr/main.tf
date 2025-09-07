resource "random_string" "sfx" {
  length  = 6
  lower   = true
  upper   = false
  special = false
}


resource "azurerm_container_registry" "acr" {
  name                = replace("${var.name_prefix}acr${random_string.sfx.result}", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}
