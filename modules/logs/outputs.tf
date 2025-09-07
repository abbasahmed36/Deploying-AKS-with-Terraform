output "la_workspace_id" {
  value = azurerm_log_analytics_workspace.app.id
}

output "la_audit_workspace_id" {
  value = azurerm_log_analytics_workspace.audit.id
}