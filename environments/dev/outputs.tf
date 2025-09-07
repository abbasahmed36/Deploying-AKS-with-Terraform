output "aks_name" { value = module.aks.cluster_name }
output "aks_rg" { value = module.aks.resource_group }
output "acr_login" { value = module.acr.login_server }
output "oidc_issuer" { value = module.aks.oidc_issuer_url }
