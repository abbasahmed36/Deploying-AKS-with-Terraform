output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.kv.id
}
output "name" {
  value = azurerm_key_vault.kv.name
}

