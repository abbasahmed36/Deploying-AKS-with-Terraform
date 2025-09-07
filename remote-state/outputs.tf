output "backend_hcl_path" {
  value = local_file.backend.filename
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_name" {
  value = azurerm_storage_container.c.name
}