output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}
output "resource_group" {
  value = var.resource_group_name
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.this.kube_config
  sensitive = true
}
