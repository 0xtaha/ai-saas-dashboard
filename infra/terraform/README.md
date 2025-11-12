# AI SaaS Dashboard - Terraform Infrastructure

This directory contains Terraform configuration for deploying the AI SaaS Dashboard infrastructure on Azure.

## Architecture Overview

The infrastructure supports two deployment modes:

### 1. Azure Managed Services Mode (`deployment_mode = "azure"`)
- **Azure Kubernetes Service (AKS)** - Orchestration platform
- **Azure Database for PostgreSQL Flexible Server** - Managed database with high availability
- **Azure Cache for Redis** - Managed caching layer
- **Azure Container Registry (ACR)** - Container image storage
- **Azure Log Analytics & Application Insights** - Monitoring and logging

### 2. On-Premise Mode (`deployment_mode = "onprem"`)
- **Azure Kubernetes Service (AKS)** - Orchestration platform
- **In-cluster PostgreSQL** - Self-hosted database pods
- **In-cluster Redis** - Self-hosted Redis pods
- **Azure Container Registry (ACR)** - Container image storage
- **Azure Log Analytics & Application Insights** - Monitoring and logging

## Prerequisites

1. **Azure CLI** - Install from [Azure CLI docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform** - Version >= 1.5.0
   ```bash
   # macOS
   brew install terraform

   # Windows
   choco install terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl** - Kubernetes command-line tool
   ```bash
   az aks install-cli
   ```

## Quick Start

### 1. Configure Terraform Backend (Optional but Recommended)

Create a storage account for Terraform state:

```bash
# Create resource group for Terraform state
az group create --name tfstate-rg --location "East US"

# Create storage account
az storage account create \
  --name tfstatestorage \
  --resource-group tfstate-rg \
  --location "East US" \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --name tfstate \
  --account-name tfstatestorage
```

Update `main.tf` backend configuration:
```hcl
backend "azurerm" {
  resource_group_name  = "tfstate-rg"
  storage_account_name = "tfstatestorage"
  container_name       = "tfstate"
  key                  = "ai-saas-dashboard.tfstate"
}
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

**For Azure Managed Services:**
```hcl
deployment_mode = "azure"
project_name    = "ai-saas-dashboard"
environment     = "prod"
location        = "East US"
```

**For On-Premise Mode:**
```hcl
deployment_mode = "onprem"
project_name    = "ai-saas-dashboard"
environment     = "prod"
location        = "East US"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the plan to ensure all resources are correct.

### 5. Apply Infrastructure

```bash
terraform apply tfplan
```

This will create:
- Resource Group
- Virtual Network with subnets
- AKS Cluster with autoscaling
- Azure Container Registry
- Log Analytics Workspace & Application Insights
- **If `deployment_mode = "azure"`:**
  - Azure Database for PostgreSQL Flexible Server
  - Azure Cache for Redis
  - Private DNS Zones
- Kubernetes namespaces and configurations

### 6. Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)
```

### 7. Verify Deployment

```bash
kubectl get nodes
kubectl get namespaces
```

## Resource Overview

### Core Infrastructure (Both Modes)

| Resource | Purpose | SKU/Size |
|----------|---------|----------|
| AKS Cluster | Container orchestration | Standard_D4s_v3 nodes |
| ACR | Container registry | Premium |
| Log Analytics | Centralized logging | PerGB2018 |
| VNet | Network isolation | 10.0.0.0/16 |

### Azure Managed Services Mode

| Resource | Purpose | Configuration |
|----------|---------|---------------|
| PostgreSQL Flexible Server | Application database | GP_Standard_D4s_v3, 128GB |
| Redis Cache | Session & caching | Premium P1 |
| Private DNS Zones | Private endpoints | Auto-configured |

### Kubernetes Resources

| Namespace | Purpose | Resources |
|-----------|---------|-----------|
| app-backend | Backend API, DB, Cache | Deployments, Services, ConfigMaps |
| app-frontend | React frontend | Deployment, Service |
| shared | Monitoring stack | Fluent Bit, Prometheus |

## Outputs

After applying, Terraform provides important outputs:

```bash
# View all outputs
terraform output

# Get specific values
terraform output aks_cluster_name
terraform output acr_login_server

# Sensitive outputs
terraform output -raw aks_kube_config
terraform output -raw postgres_admin_password  # Azure mode only
terraform output -raw redis_primary_access_key # Azure mode only
```

## Cost Estimation

### Azure Managed Services Mode (Monthly)
- AKS Cluster (3x D4s_v3): ~$400
- PostgreSQL Flexible Server (D4s_v3): ~$350
- Redis Cache (Premium P1): ~$300
- ACR (Premium): ~$40
- Log Analytics: ~$50
- **Total: ~$1,140/month**

### On-Premise Mode (Monthly)
- AKS Cluster (3x D4s_v3): ~$400
- ACR (Premium): ~$40
- Log Analytics: ~$50
- **Total: ~$490/month**

*Note: Costs vary based on region, data transfer, and actual usage.*

## Deployment Modes Comparison

| Feature | Azure Mode | On-Premise Mode |
|---------|-----------|-----------------|
| **Database** | Azure PostgreSQL Flexible Server | PostgreSQL in AKS |
| **Caching** | Azure Cache for Redis | Redis in AKS |
| **High Availability** | Built-in (Zone Redundant) | Manual configuration |
| **Backup** | Automated (7-day retention) | Manual setup required |
| **Scaling** | Auto-scaling compute + storage | Manual pod scaling |
| **Maintenance** | Microsoft managed | Self-managed |
| **Cost** | Higher (~$1,140/mo) | Lower (~$490/mo) |
| **Performance** | Better (dedicated resources) | Good (shared resources) |
| **Security** | Private endpoints, VNet integration | Network policies |

## Switching Between Modes

To switch deployment modes:

1. Update `terraform.tfvars`:
   ```hcl
   deployment_mode = "onprem"  # or "azure"
   ```

2. Plan changes:
   ```bash
   terraform plan
   ```

3. Apply changes:
   ```bash
   terraform apply
   ```

**Warning:** Switching from Azure to on-premise mode will **destroy** managed PostgreSQL and Redis resources. Ensure data is backed up before switching.

## Disaster Recovery

### Azure Mode
- PostgreSQL: Geo-redundant backups (7 days)
- Redis: RDB snapshots to storage account
- AKS: Velero backup recommended

### On-Premise Mode
- PostgreSQL: Manual backup scripts required
- Redis: RDB persistence to PVC
- AKS: Velero backup recommended

## Security Best Practices

1. **Enable Private Endpoints** (Azure mode)
   - Already configured for PostgreSQL and Redis Premium

2. **Network Policies**
   - Applied for pod-to-pod communication

3. **RBAC**
   - Azure AD integration enabled on AKS
   - Use `az aks get-credentials --admin` for admin access

4. **Secrets Management**
   - Use Azure Key Vault for sensitive values
   - Secrets created by Terraform are stored in Kubernetes

5. **Container Security**
   - ACR content trust enabled
   - Image scanning with Azure Defender

## Troubleshooting

### Issue: Terraform state lock

```bash
terraform force-unlock <lock-id>
```

### Issue: AKS cluster creation timeout

Increase timeout in provider configuration or check Azure service health.

### Issue: PostgreSQL connection failed

Check firewall rules:
```bash
az postgres flexible-server firewall-rule list \
  --resource-group <rg-name> \
  --name <server-name>
```

### Issue: Redis connection failed

Verify VNet integration and SSL requirements.

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy
```

**Warning:** This will delete all resources including databases. Ensure backups exist before destroying.

## CI/CD Integration

The GitHub Actions workflow automatically deploys based on deployment mode:

```yaml
- name: Terraform Apply
  env:
    TF_VAR_deployment_mode: ${{ secrets.DEPLOYMENT_MODE }}
  run: terraform apply -auto-approve
```

## Support

For issues or questions:
- Check [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- Check [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- Review deployment logs in Log Analytics workspace

## File Structure

```
infra/terraform/
├── main.tf                  # Provider configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── resource-group.tf        # Resource group
├── networking.tf            # VNet, subnets, NSG
├── aks.tf                   # AKS cluster configuration
├── acr.tf                   # Container registry
├── postgres.tf              # PostgreSQL (Azure mode)
├── redis.tf                 # Redis Cache (Azure mode)
├── monitoring.tf            # Log Analytics, App Insights, Alerts
├── kubernetes-config.tf     # K8s namespaces, secrets, policies
├── terraform.tfvars.example # Example variables
└── README.md                # This file
```
