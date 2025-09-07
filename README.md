# Deploying AKS with Terraform

This repository contains Terraform code to deploy an **Azure Kubernetes Service (AKS)** environment along with supporting resources like ACR, Key Vault, Monitoring, Networking, and Logging.  
The project follows an **environment-based structure** (`dev`, `test`, etc.) and uses **remote state** for consistency.

---

##  Recommended Versions

- **Terraform CLI**: `>= 1.6.0`
- **Providers**:
  - `azurerm`    ~> `4.120` (latest tested: 4.123.0)
  - `kubernetes` ~> `2.34`
  - `helm`       ~> `2.14`
  - `random`     ~> `3.6`

---

## 🚀 Getting Started


### Prerequisites
- Azure CLI installed
- Terraform `>= 1.6`
- Sufficient Azure permissions (Contributor on target subscription)


### Authenticate

** User login**

```bash
az login --use-device-code
SUB_ID="<your-subscription-id>"
az account set --subscription "$SUB_ID"
```
###  Service principal

```bash

# Create once
az ad sp create-for-rbac --name "terraform" --skip-assignment --years 2 -o json

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
## Initialize Remote State 

```bash
terraform -chdir=remote-state init
terraform -chdir=remote-state apply
```
Create the backend config for dev

```bash
cat > environments/dev/backend.hcl <<'EOF'
resource_group_name  = "tfstate-rg"
storage_account_name = "tfstateggn52c"
container_name       = "tfstate"
key                  = "aks/dev.tfstate"
EOF
```

## Dev Environment: Init → Plan → Apply

```bash
# Init with remote backend
terraform -chdir=environments/dev init -backend-config=backend.hcl

# Format & validate
terraform -chdir=environments/dev fmt -recursive
terraform -chdir=environments/dev validate

# Preview changes
terraform -chdir=environments/dev plan -out tfplan

# Apply
terraform -chdir=environments/dev apply tfplan
```
Destroy if needed:

```bash
terraform -chdir=environments/dev destroy

```


**Cluster posture:** local accounts disabled and Azure RBAC for Kubernetes enabled.

**Each user/SP needs:** Azure Kubernetes Service Cluster User Role on the AKS resource (to run az aks get-credentials), and

An Azure Kubernetes Service RBAC * role (Reader/Writer/Admin/Cluster Admin) at cluster or namespace scope (to do things inside the cluster).

```bash
WHO="<user-objectId | appId >"

#From repo root:
TFDIR="environments/dev"

# Fetch values from Terraform outputs
AKS_NAME=$(terraform -chdir="$TFDIR" output -raw aks_name)
AKS_RG=$(terraform -chdir="$TFDIR" output -raw aks_rg)
ACR_LOGIN=$(terraform -chdir="$TFDIR" output -raw acr_login)
OIDC_ISSUER=$(terraform -chdir="$TFDIR" output -raw oidc_issuer)

echo "AKS: $AKS_NAME"
echo "RG:  $AKS_RG"
echo "ACR: $ACR_LOGIN"
echo "OIDC: $OIDC_ISSUER"

# AKS resource ID
AKS_ID=$(az aks show -g "$RG" -n "$AKS_NAME" --query id -o tsv)
```

 Cluster-wide admin (full control)
```bash
az role assignment create --assignee "$WHO" \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope "$AKS_ID"

```
## Connecting to AKS

```bash

# Get kubeconfig (no --admin)
az aks get-credentials -g "$AKS_RG" -n "$AKS_NAME" --overwrite-existing

# Verify
kubectl cluster-info
kubectl get nodes -o wide

# Login to ACR (CLI expects registry name, not FQDN)
ACR_NAME="${ACR_LOGIN%%.*}"
az acr login -n "$ACR_NAME"
```
## Cluster Profile (Current)
- **Dataplane:** Cilium (Azure CNI powered by Cilium)

- **Admin accounts:** Disabled (no local cluster admin); Azure RBAC for Kubernetes is enabled

- **Topology:** Single VNet with a single Subnet (nodes + pods share the same subnet)

- **API Server Access:** Public endpoint with IP allowlist (authorized IP ranges)

- **Node Pools:** 1 system pool + 1 user pool

- **Region:** swedencentral

- **AKS SKU:** Free

- **Logging:** Retention 30 days

- **Tags:** { env = "dev" }

- **OIDC Issuer:**  Not yet used (planned for Workload Identity)

See environments/dev/terraform.tfvars for current values.
Note: If your module requires create_user_pool = true to actually create the user pool, set it accordingly before plan/apply.

## API Server Allowlist (Authorized IP Ranges)
Configured in terraform.tfvars:

```bash
# Public API; whitelist specific clients here
authorized_ip_ranges = []
# Example:
# authorized_ip_ranges = ["203.0.113.45/32", "198.51.100.0/24"]
```
To restrict access, set your IP/CIDRs and re-plan/apply.
If you later switch to a private cluster, remove/ignore this and use private connectivity (VPN/ER/jump host).

Current environments/dev/terraform.tfvars 

```bash
# ---- Naming & Region ----
prefix             = "aksbl"
location           = "swedencentral"
kubernetes_version = null #  AKS pick the latest

# ---- VNet/Subnet for AKS nodes ----
vnet_cidr       = "10.10.0.0/16"
aks_subnet_cidr = "10.10.0.0/22"

# ---- In-cluster networking (must not overlap VNet) ----
dns_service_ip = "10.2.0.10"
service_cidr   = "10.2.0.0/24"

# ---- Node pool sizing  ----
#system_vm_size    = "Standard_D2as_v5"
#system_vm_size    = "Standard_DS2_v2"
system_vm_size = "Standard_B2s"

system_node_count = 1
create_user_pool  = true
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
```


##  Roadmap (Next Update)
Planned items for the next monthly update:

- Workload Identity

  - Enable OIDC issuer + Workload Identity on AKS

  - Create User-Assigned Managed Identity (UAMI) and Federated Identity Credential (FIC) per workload

  - Use wi_namespace + wi_service_account from vars

- Private Endpoints for Azure resources

  - Add Private Endpoints/Private DNS for Key Vault, ACR, and (if used) Storage

  - Convert to a private AKS API server + private connectivity

- Network segmentation

  - Split single subnet into two subnets: one for system nodes and one for user nodes

  - Update modules/variables to place pools on the correct subnet

