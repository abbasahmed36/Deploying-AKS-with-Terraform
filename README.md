# Deploying AKS with Terraform

This project provisions an Azure Kubernetes Service (AKS) environment using Terraform, showcasing my hands-on experience with cloud infrastructure, infrastructure as code (IaC), and Kubernetes best practices for real-world scenarios.

**Scope note**: Per project scope, this README intentionally **excludes Governance/Azure Policy and Workload Identity** details. Those can be added later.


---

## What Gets Created

- **Resource Groups**
  - `aksbl-rg` (core / AKS)
  - `aksbl-acr-rg` (container registry)
  - `aksbl-audit-rg` (Log Analytics / audit)
- **Networking**
  - Virtual Network `aksbl-vnet`
  - Subnets: `aksbl-snet-aks-system`, `aksbl-snet-aks-user`, `aksbl-snet-aks-privatepoint`
  - Private DNS zones + VNet links:
    - `privatelink.azurecr.io`
    - `privatelink.vaultcore.azure.net`
- **Registries & Secrets**
  - ACR: `aksblacrl9ekbj` (Premium, admin disabled)
  - Key Vault: `aksbl-kv-<suffix>` with RBAC, soft‑delete, purge protection, Private Endpoint
- **AKS**
  - Cluster: `aksbl-aks` with Azure RBAC
  - Node pools: default **system** + **user1** (separate subnet)
  - Diagnostic setting: `AksLogging` to Log Analytics
- **Observability**
  - Azure Monitor Workspace: `aksbl-amw`
  - Data Collection Rule (Prometheus) + association to the cluster
  - Managed Grafana: `aksbl-amg` with Reader on AMW
  - Log Analytics workspaces: `aksbl-la` and `aksbl-la-audit`

---

## Prerequisites

- Azure CLI ≥ 2.50, Terraform ≥ 1.6
- Azure subscription with permissions to create RGs/resources
- **Authentication**: run Terraform as a **Service Principal** (recommended) or as a user


### Authenticate

** User login **

```bash
az login --use-device-code
SUB_ID="<your-subscription-id>"
az account set --subscription "$SUB_ID"
```
###  Service principal

```bash

# Create once

az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/$SUB_ID \
  --sdk-auth

# Save and source before runs
cat > terraform.env <<'EOF'
export ARM_CLIENT_ID="<APP_ID>"
export ARM_CLIENT_SECRET="<PASSWORD>"
export ARM_TENANT_ID="<TENANT_ID>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
EOF
source terraform.env

# Use SP for az as well (recommended for CI)
az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
az account set --subscription "$ARM_SUBSCRIPTION_ID"
```
now format the remote state

```bash
terraform -chdir=remote-state fmt -recursive
```
## Initialize Remote State and apply 

```bash
# init providers
terraform -chdir=remote-state init

# validate config
terraform -chdir=remote-state validate

# draft a plan
terraform -chdir=remote-state plan \
  -var 'location=swedencentral' \
  -var 'rg_name=tfstate-rg' \
  -var 'account_name=tfstate54aks' \
  -var 'container_name=tfstate' \
  -var 'key=aks/dev.tfstate' \
  -out remote-state.plan

# apply exactly that plan
terraform -chdir=remote-state apply remote-state.plan
```

## Dev Environment: Init → Plan → Apply

```bash
# Init with remote backend
terraform -chdir=environments/dev init \
  -reconfigure \
  -backend-config=../../remote-state/backend.hcl

# Format & validate
terraform -chdir=environments/dev fmt -recursive
terraform -chdir=environments/dev validate

# Preview changes
terraform -chdir=environments/dev plan -out tfplan

# Apply
terraform -chdir=environments/dev apply tfplan
```

**Cluster posture:** local accounts disabled and Azure RBAC for Kubernetes enabled.

**Each user/SP needs:** Azure Kubernetes Service Cluster User Role on the AKS resource (to run az aks get-credentials), and

An Azure Kubernetes Service RBAC * role (Reader/Writer/Admin/Cluster Admin) at cluster or namespace scope (to do things inside the cluster).

Now Get the user creds

```bash
az aks get-credentials -g aksbl-rg -n aksbl-aks --overwrite-existing

```
Ensure your identity has the right roles on the AKS resource

```bash
AKS_ID=$(az aks show -g aksbl-rg -n aksbl-aks --query id -o tsv)

```
as i am logged in as SP so

```bash
SP_OBJ_ID=$(az ad sp show --id "$ARM_CLIENT_ID" --query id -o tsv)

# Needed to fetch/use user credentials:
az role assignment create --assignee-object-id "$SP_OBJ_ID" --assignee-principal-type ServicePrincipal \
  --role "Azure Kubernetes Service Cluster User Role" --scope "$AKS_ID"

# Give cluster-admin inside Kubernetes (when Azure RBAC is enabled):
az role assignment create --assignee-object-id "$SP_OBJ_ID" --assignee-principal-type ServicePrincipal \
  --role "Azure Kubernetes Service RBAC Cluster Admin" --scope "$AKS_ID"

```
Then convert kubeconfig to use SP login and test:
```bash
az aks install-cli
kubelogin convert-kubeconfig -l spn \
  --client-id "$ARM_CLIENT_ID" --client-secret "$ARM_CLIENT_SECRET" --tenant-id "$ARM_TENANT_ID"

kubectl get nodes

```

Current environments/dev/terraform.tfvars 

```bash
# ---- Naming & Region ----
prefix             = "aksbl"
location           = "swedencentral"
kubernetes_version = null #  AKS pick the latest

# ---- VNet/Subnet for AKS nodes ----
vnet_cidr                = "10.40.0.0/16" # must contain the subnets below
system_subnet_cidr       = "10.40.0.0/22"
user_subnet_cidr         = "10.40.4.0/22"
privendpoint_subnet_cidr = "10.40.8.0/24"
# ---- In-cluster networking (must not overlap VNet) ----
dns_service_ip = "10.2.0.10"
service_cidr   = "10.2.0.0/24"

# ---- Node pool sizing  ----
#system_vm_size    = "Standard_D2as_v5"
#system_vm_size    = "Standard_DS2_v2"
system_vm_size = "Standard_B2s"

system_node_count = 1
create_user_pool  = true
#create_user_pool  = true
#user_vm_size      = "Standard_D2as_v5"
#user_vm_size = "Standard_DS2_v2"
user_vm_size = "Standard_B2s"

user_node_count = 1

# ---- API server access (public API case) ----
authorized_ip_ranges = []
# authorized_ip_ranges = ["<YOUR.IP>/32"]

# ---- AKS SKU ----
sku_tier = "Free"

# ---- Logs ----
logs_retention = 30

# ---- Tags ----
tags = { env = "dev" }

# ---- Workload Identity + Key Vault ----
wi_namespace       = "app"
wi_service_account = "api"
#kv_name            = "my-dev-keyvault"
kv_name = "aksbl-kv-d8kj03"
seed_secret_name = "my-secret-v2"

```
## Clean Up

```
terraform -chdir=remote-state destroy
terraform -chdir=environments/dev destroy

# or you can delete resource group forcefully through az cli
az group delete --name <resourceGroup> --yes --no-wait
```
