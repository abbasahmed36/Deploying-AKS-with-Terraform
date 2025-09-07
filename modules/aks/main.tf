
data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-dns"

  kubernetes_version = var.kubernetes_version
  identity { type = "SystemAssigned" }

  # Cluster access: Entra ID + Azure RBAC, no local admin
  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
    # admin_group_object_ids = ["<aad-group-guid>"]
  }
  local_account_disabled = true

  # Workload Identity capability 
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Cilium dataplane
  network_profile {
    network_plugin = "azure"
    # Optional overlay to save IPs:
    # network_plugin_mode = "overlay"
    # pod_cidr            = "10.244.0.0/16"
    network_data_plane = "cilium"

    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
  }

  # Key Vault CSI driver
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2h"
  }

  # System pool
  default_node_pool {
    name            = "system"
    vm_size         = var.system_vm_size
    node_count      = var.system_node_count
    vnet_subnet_id  = var.subnet_id
    os_disk_type    = "Managed"
    os_disk_size_gb = 100
    upgrade_settings { max_surge = "33%" }
    # Add 'zones = ["1","2","3"]' will add later
  }

  # Observability & governance
  oms_agent { log_analytics_workspace_id = var.la_workspace_id }
  azure_policy_enabled = true
  sku_tier             = var.sku_tier

  # Public API allowlist 
  api_server_access_profile { authorized_ip_ranges = var.authorized_ip_ranges }

  tags = var.tags
}

# user pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.create_user_pool ? 1 : 0

  name                  = "user1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  mode                  = "User"
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.subnet_id
  os_disk_type          = "Managed"
  os_disk_size_gb       = 100
  upgrade_settings { max_surge = "33%" }

  tags = var.tags
}

# Diagnostics - audit workspace
resource "azurerm_monitor_diagnostic_setting" "diag" {
  name                       = "AksLogging"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.la_audit_workspace_id

  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "cluster-autoscaler" }
  enabled_log { category = "guard" } # comment if unsupported
  enabled_metric { category = "AllMetrics" }
}

# Let kubelet pull from  ACR
resource "azurerm_role_assignment" "acr_pull" {
  count               = var.enable_acr_role_assignment ? 1 : 0
  scope               = var.acr_id
  role_definition_name = "AcrPull"
  principal_id        = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
