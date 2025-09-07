resource "azurerm_log_analytics_workspace" "app" {
  name                = "${var.name_prefix}-la"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.tags
}


resource "azurerm_log_analytics_workspace" "audit" {
  name                = "${var.name_prefix}-la-audit"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.tags
}
