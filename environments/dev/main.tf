########################################
# locals
########################################
locals {
  name_prefix    = var.prefix
  rg_main        = "${var.prefix}-rg"
  rg_audit       = "${var.prefix}-audit-rg"
  rg_acr         = "${var.prefix}-acr-rg"
  retention_days = var.logs_retention
  tags           = var.tags
}

########################################
# Resource Groups
########################################
resource "azurerm_resource_group" "main" {
  name     = local.rg_main
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "audit" {
  name     = local.rg_audit
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "acr" {
  name     = local.rg_acr
  location = var.location
  tags     = local.tags
}

########################################
# Networking (VNet + AKS subnet)
########################################
module "network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  vnet_name = "${var.prefix}-vnet"
  vnet_cidr = var.vnet_cidr
  subnets = {
    system = {
      name             = "${var.prefix}-snet-aks-system"
      address_prefixes = [var.system_subnet_cidr]
    }
    user = {
      name             = "${var.prefix}-snet-aks-user"
      address_prefixes = [var.user_subnet_cidr]
    }
    privendpoint = {
      name             = "${var.prefix}-snet-aks-privatepoint"
      address_prefixes = [var.privendpoint_subnet_cidr]
    }

  }
  tags = local.tags
}

########################################
# Log Analytics
########################################
module "logs_app" {
  source              = "../../modules/logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  name_prefix         = var.prefix
  retention_days      = local.retention_days
  tags                = local.tags
}

# Dedicated audit workspace in audit RG
module "logs_audit" {
  source              = "../../modules/logs"
  resource_group_name = azurerm_resource_group.audit.name
  location            = var.location
  name_prefix         = "${var.prefix}-audit"
  retention_days      = local.retention_days
  tags                = local.tags
}

########################################
# ACR
########################################
module "acr" {
  source              = "../../modules/acr"
  resource_group_name = azurerm_resource_group.acr.name
  location            = var.location
  name_prefix         = var.prefix
  tags                = local.tags
}

########################################
# AKS cluster (Cilium + WI + KV CSI)
########################################
module "aks" {
  source = "../../modules/aks"

  # Naming / location
  name                = "${var.prefix}-aks"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  kubernetes_version  = var.kubernetes_version

  # Networking
  subnet_id      = module.network.subnet_ids["system"]
  dns_service_ip = var.dns_service_ip
  service_cidr   = var.service_cidr

  # Observability
  la_workspace_id       = module.logs_app.la_workspace_id
  la_audit_workspace_id = module.logs_audit.la_audit_workspace_id

  # ACR integration
  acr_id = module.acr.acr_id

  # Node pool sizing
  system_vm_size    = var.system_vm_size
  system_node_count = var.system_node_count
  create_user_pool  = var.create_user_pool
  user_vm_size      = var.user_vm_size
  user_node_count   = var.user_node_count

  # API server allowlist (public API )
  authorized_ip_ranges = var.authorized_ip_ranges

  # Tier & tags
  sku_tier = var.sku_tier
  tags     = local.tags
}

########################################
# Key Vault (RBAC enabled) + seed secret
########################################
module "keyvault" {
  source              = "../../modules/keyvault"
  kv_name             = var.kv_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  #  create an example secret named "my-secret"
  create_seed_secret = true
    seed_secret_name = var.seed_secret_name

  #seed_secret_name   = "my-secret"
  # seed_secret_value = "hello-from-kv"
}


########################################
# Managed Prometheus + Managed Grafana
########################################
module "monitoring" {
  source              = "../../modules/monitoring"
  name_prefix         = var.prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  aks_id              = module.aks.cluster_id
}

########################################
# Private Endpoint For key vault
########################################

module "pe_kv" {
  source              = "../../modules/private_endpoint"
  name                = "${var.prefix}-pe-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  subnet_id = module.network.subnet_ids["privendpoint"]
  vnet_id   = module.network.vnet_id

  target_resource_id     = module.keyvault.key_vault_id
  subresource_names      = ["vault"]
  private_dns_zone_names = ["privatelink.vaultcore.azure.net"]

  tags = local.tags
}

########################################
# Private Endpoint For ACR
########################################



module "pe_acr" {
  source              = "../../modules/private_endpoint"
  name                = "${var.prefix}-pe-acr"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  subnet_id              = module.network.subnet_ids["privendpoint"]
  vnet_id                = module.network.vnet_id
  target_resource_id     = module.acr.acr_id
  subresource_names      = ["registry"]
  private_dns_zone_names = ["privatelink.azurecr.io"]
  tags                   = local.tags
}
