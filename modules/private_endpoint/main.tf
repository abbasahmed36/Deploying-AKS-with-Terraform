data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

resource "azurerm_private_dns_zone" "this" {
  for_each            = toset(var.private_dns_zone_names)
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the zones to the VNet so AKS nodes resolve private FQDNs
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = azurerm_private_dns_zone.this
  name                  = "link-${replace(each.value.name, ".", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = var.target_resource_id
    is_manual_connection           = false
    subresource_names              = var.subresource_names
  }

  # Bind the endpoint to the DNS zones so records are created
  private_dns_zone_group {
    name                 = "${var.name}-pdzg"
    private_dns_zone_ids = [for z in azurerm_private_dns_zone.this : z.id]
  }
}

output "private_endpoint_id" {
  value = azurerm_private_endpoint.this.id
}

