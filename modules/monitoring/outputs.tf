output "grafana_name" {
  value = azurerm_dashboard_grafana.amg.name
}

output "amw_id" {
  value = azurerm_monitor_workspace.amw.id
}

