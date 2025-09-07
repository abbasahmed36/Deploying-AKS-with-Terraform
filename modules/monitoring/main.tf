# modules/monitoring/main.tf
# Managed Prometheus (Azure Monitor workspace + DCR) and Managed Grafana.

# 1) Azure Monitor Workspace (Prometheus metrics store)
resource "azurerm_monitor_workspace" "amw" {
  name                = "${var.name_prefix}-amw"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# 2) Data Collection Rule to route Prometheus metrics to the workspace
resource "azurerm_monitor_data_collection_rule" "prom" {
  name                = "${var.name_prefix}-dcr-prom"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Destination: the Azure Monitor workspace above
  destinations {
    monitor_account {
      name               = "amw"
      monitor_account_id = azurerm_monitor_workspace.amw.id
    }
  }

  # Data source: Prometheus forwarder (v4 requires 'streams' here too)
  data_sources {
    prometheus_forwarder {
      name    = "k8s"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  # Route the Prometheus stream to the destination
  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["amw"]
  }
}

# 3) Associate the DCR to your AKS managed cluster
resource "azurerm_monitor_data_collection_rule_association" "aks_prom" {
  name                    = "${var.name_prefix}-dcrassoc"
  target_resource_id      = var.aks_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prom.id
}

# 4) Azure Managed Grafana (v4 requires grafana_major_version)
resource "azurerm_dashboard_grafana" "amg" {
  name                = "${var.name_prefix}-amg"
  resource_group_name = var.resource_group_name
  location            = var.location

  identity { type = "SystemAssigned" }

  sku                   = "Standard"
  grafana_major_version = "11"
}

# 5) Allow Grafana to read from the Azure Monitor workspace
resource "azurerm_role_assignment" "amg_reader" {
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = "Reader"
  principal_id         = azurerm_dashboard_grafana.amg.identity[0].principal_id
}

