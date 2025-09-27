data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = var.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = true
}


# Give the Terraform caller permission to manage secrets (DATA-PLANE)
resource "azurerm_role_assignment" "secret_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


# Waiting time for RBAC to propagate
resource "time_sleep" "wait_for_kv_rbac" {
  depends_on = [
    azurerm_role_assignment.secret_officer
  ]
  create_duration = "300s"
}

resource "azurerm_key_vault_secret" "seed" {
  count        = var.create_seed_secret ? 1 : 0
  name         = var.seed_secret_name
  value        = var.seed_secret_value != null ? var.seed_secret_value : "hello-from-kv"
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_kv_rbac]
}
