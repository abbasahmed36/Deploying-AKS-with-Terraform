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

