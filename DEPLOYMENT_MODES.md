# AI SaaS Dashboard - Deployment Modes Guide

This document explains the two deployment modes available for the AI SaaS Dashboard and how to use them.

## Overview

The application supports two deployment architectures:

1. **Azure Managed Services Mode** - Uses Azure Database for PostgreSQL and Azure Cache for Redis
2. **On-Premise Mode** - Runs PostgreSQL and Redis as containers within the AKS cluster

## Deployment Modes Comparison

| Feature | Azure Mode | On-Premise Mode |
|---------|-----------|-----------------|
| **Database** | Azure Database for PostgreSQL Flexible Server | PostgreSQL pod in AKS |
| **Cache** | Azure Cache for Redis (Premium) | Redis pod in AKS |
| **High Availability** | Zone-redundant, auto-failover | Requires manual configuration |
| **Backup & Recovery** | Automated (7-day retention, geo-redundant) | Manual setup required |
| **Scaling** | Independent scaling of DB/Cache | Limited by pod resources |
| **Maintenance** | Managed by Microsoft | Self-managed |
| **Performance** | Dedicated resources, optimized | Good, but shared node resources |
| **Security** | Private endpoints, VNet integration | Network policies |
| **Monitoring** | Built-in Azure Monitor integration | Prometheus + custom exporters |
| **Cost (est.)** | ~$1,140/month | ~$490/month |
| **Best For** | Production workloads | Development, testing, cost-sensitive |

## Architecture Diagrams

### Azure Managed Services Mode

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Subscription                        │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Azure Kubernetes Service                │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │   │
│  │  │ app-backend  │  │ app-frontend │  │  shared   │ │   │
│  │  │              │  │              │  │           │ │   │
│  │  │ Backend API  │  │   Frontend   │  │ Fluent    │ │   │
│  │  │    Pods      │  │     Pods     │  │ Bit       │ │   │
│  │  │              │  │              │  │ Prometheus│ │   │
│  │  └──────┬───────┘  └──────────────┘  └───────────┘ │   │
│  │         │                                           │   │
│  └─────────┼───────────────────────────────────────────┘   │
│            │                                                │
│            ├──────────────────┬──────────────────┐         │
│            │                  │                  │         │
│  ┌─────────▼─────────┐ ┌─────▼────────┐ ┌──────▼───────┐ │
│  │ Azure PostgreSQL  │ │ Azure Redis  │ │     ACR      │ │
│  │ Flexible Server   │ │    Cache     │ │  (Images)    │ │
│  │                   │ │              │ │              │ │
│  │ • Zone Redundant  │ │ • Premium    │ │              │ │
│  │ • Auto Backup     │ │ • Clustered  │ │              │ │
│  │ • Private Endpoint│ │ • Private EP │ │              │ │
│  └───────────────────┘ └──────────────┘ └──────────────┘ │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │           Log Analytics Workspace                  │   │
│  │         Application Insights                       │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### On-Premise Mode

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Subscription                        │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Azure Kubernetes Service                │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │   │
│  │  │ app-backend  │  │ app-frontend │  │  shared   │ │   │
│  │  │              │  │              │  │           │ │   │
│  │  │ Backend API  │  │   Frontend   │  │ Fluent    │ │   │
│  │  │    Pods      │  │     Pods     │  │ Bit       │ │   │
│  │  │              │  │              │  │ Prometheus│ │   │
│  │  │ ┌──────────┐ │  │              │  │           │ │   │
│  │  │ │PostgreSQL│ │  │              │  │           │ │   │
│  │  │ │   Pod    │ │  │              │  │           │ │   │
│  │  │ │          │ │  │              │  │           │ │   │
│  │  │ │ ┌──────┐ │ │  │              │  │           │ │   │
│  │  │ │ │Redis │ │ │  │              │  │           │ │   │
│  │  │ │ │ Pod  │ │ │  │              │  │           │ │   │
│  │  │ └─┴──────┴─┘ │  │              │  │           │ │   │
│  │  └──────────────┘  └──────────────┘  └───────────┘ │   │
│  │                                                       │   │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────┐  ┌────────────────────────────────┐     │
│  │     ACR      │  │   Log Analytics Workspace      │     │
│  │  (Images)    │  │   Application Insights         │     │
│  └──────────────┘  └────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Both Modes
- Azure CLI installed and configured
- kubectl installed
- Docker installed (for local testing)
- Access to Azure subscription with appropriate permissions

### Azure Mode Additional Requirements
- Terraform (for infrastructure provisioning)
- Sufficient Azure quota for:
  - Azure Database for PostgreSQL Flexible Server
  - Azure Cache for Redis Premium
  - Private DNS zones

## Setup Instructions

### Option 1: Using Terraform (Recommended)

#### 1. Configure Terraform Variables

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

**For Azure Mode:**
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

#### 2. Initialize and Apply Terraform

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform will create:
- AKS cluster
- Azure Container Registry
- Log Analytics & Application Insights
- Virtual Network with subnets
- **If Azure mode:** PostgreSQL Flexible Server, Redis Cache, Private Endpoints
- Kubernetes namespaces and secrets

#### 3. Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)
```

#### 4. Deploy Application

```bash
cd ../../scripts/deploy

# For Azure mode
./deploy-with-mode.sh azure

# For On-premise mode
./deploy-with-mode.sh onprem
```

### Option 2: Manual Setup

#### 1. Create Secrets

```bash
cd scripts/deploy
./create-secrets.sh
```

Follow prompts to enter:
- Backend secrets (SECRET_KEY, JWT_SECRET_KEY, etc.)
- Azure services credentials (if Azure mode)
- Monitoring credentials

#### 2. Deploy with Mode Selection

```bash
./deploy-with-mode.sh [azure|onprem]
```

## GitHub Actions CI/CD

### Configure Secrets

Add these secrets to your GitHub repository:

#### Required for Both Modes
```
AZURE_CREDENTIALS
AZURE_CONTAINER_REGISTRY
AKS_CLUSTER_NAME
AKS_RESOURCE_GROUP
ACR_USERNAME
ACR_PASSWORD
SECRET_KEY
JWT_SECRET_KEY
POSTGRES_PASSWORD
REDIS_PASSWORD
AI_API_KEY
AI_API_URL
AZURE_LOG_ANALYTICS_WORKSPACE_ID
AZURE_LOG_ANALYTICS_WORKSPACE_KEY
MONITORING_PASSWORD
SLACK_WEBHOOK (optional)
```

#### Additional for Azure Mode
```
DEPLOYMENT_MODE=azure
AZURE_POSTGRES_HOST
AZURE_POSTGRES_PASSWORD
AZURE_REDIS_HOST
AZURE_REDIS_KEY
```

### Manual Deployment Workflow

1. Go to **Actions** tab in GitHub
2. Select **CD - Deploy to Azure AKS**
3. Click **Run workflow**
4. Select:
   - **Environment**: dev/staging/prod
   - **Deployment Mode**: azure/onprem
5. Click **Run workflow**

### Automatic Deployment

Push to `main` branch triggers automatic deployment with the mode specified in `DEPLOYMENT_MODE` secret.

## Configuration Files

### Azure Mode
- [k8s/overlays/azure/backend-config.yaml](k8s/overlays/azure/backend-config.yaml) - Azure-specific configuration
- [k8s/overlays/azure/backend-patch.yaml](k8s/overlays/azure/backend-patch.yaml) - Environment variable overrides
- [k8s/overlays/azure/azure-secrets.yaml](k8s/overlays/azure/azure-secrets.yaml) - Azure services credentials template

### On-Premise Mode
- [k8s/overlays/onprem/backend-config.yaml](k8s/overlays/onprem/backend-config.yaml) - On-premise configuration
- [k8s/base/postgres-deployment.yaml](k8s/base/postgres-deployment.yaml) - PostgreSQL StatefulSet
- [k8s/base/redis-deployment.yaml](k8s/base/redis-deployment.yaml) - Redis Deployment

## Environment Variables

### Backend Configuration

#### Azure Mode
```env
DATABASE_HOST=<postgres-server>.postgres.database.azure.com
DATABASE_PORT=5432
DATABASE_NAME=ai_saas_db
DATABASE_USER=dbadmin
DATABASE_SSL_MODE=require

REDIS_HOST=<redis-cache>.redis.cache.windows.net
REDIS_PORT=6380
REDIS_SSL=true
REDIS_PASSWORD=<from-azure-secret>
```

#### On-Premise Mode
```env
DATABASE_HOST=postgres-service.app-backend.svc.cluster.local
DATABASE_PORT=5432
DATABASE_NAME=ai_saas_db
DATABASE_USER=postgres
DATABASE_SSL_MODE=prefer

REDIS_HOST=redis-service.app-backend.svc.cluster.local
REDIS_PORT=6379
REDIS_SSL=false
REDIS_PASSWORD=<optional>
```

## Monitoring and Observability

### Both Modes
- **Fluent Bit**: Collects logs from all pods and ships to Azure Log Analytics
- **Prometheus**: Scrapes metrics from backend, frontend, and monitoring components
- **Application Insights**: Tracks application performance and errors

### Accessing Monitoring

#### Prometheus UI
```bash
kubectl port-forward -n shared svc/prometheus-service 9090:9090
```
Then access: http://localhost:9090

#### Azure Log Analytics
Navigate to Azure Portal → Log Analytics Workspace → Logs

Sample query:
```kusto
KubernetesLogs
| where Namespace in ("app-backend", "app-frontend", "shared")
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
```

## Switching Between Modes

### Using Terraform

1. Update `terraform.tfvars`:
   ```hcl
   deployment_mode = "onprem"  # or "azure"
   ```

2. Apply changes:
   ```bash
   terraform plan
   terraform apply
   ```

3. Redeploy application:
   ```bash
   cd ../../scripts/deploy
   ./deploy-with-mode.sh [azure|onprem]
   ```

**⚠️ Warning:** Switching from Azure to on-premise will destroy Azure PostgreSQL and Redis resources. **Backup data first!**

### Backup Before Switching

#### PostgreSQL Backup (Azure Mode)
```bash
# Automated backups available for 7 days in Azure
# For manual backup:
pg_dump -h <postgres-host> -U dbadmin -d ai_saas_db > backup.sql
```

#### PostgreSQL Backup (On-Premise Mode)
```bash
kubectl exec -n app-backend <postgres-pod> -- \
  pg_dump -U postgres ai_saas_db > backup.sql
```

## Troubleshooting

### Azure Mode Issues

#### Cannot connect to PostgreSQL
```bash
# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group <rg-name> \
  --name <server-name>

# Verify private endpoint
kubectl get pods -n app-backend -o wide
nslookup <postgres-fqdn>
```

#### Cannot connect to Redis
```bash
# Test Redis connection
kubectl run -it --rm redis-test --image=redis:alpine --restart=Never -- \
  redis-cli -h <redis-host> -p 6380 --tls -a <password> PING
```

### On-Premise Mode Issues

#### PostgreSQL pod not starting
```bash
kubectl logs -n app-backend <postgres-pod>
kubectl describe pod -n app-backend <postgres-pod>

# Check PVC
kubectl get pvc -n app-backend
```

#### Redis pod failing
```bash
kubectl logs -n app-backend <redis-pod>

# Check if Redis is responding
kubectl exec -n app-backend <redis-pod> -- redis-cli PING
```

### General Issues

#### Backend cannot connect to database
```bash
# Check backend logs
kubectl logs -n app-backend deployment/backend

# Verify ConfigMap
kubectl get configmap backend-config -n app-backend -o yaml

# Check secrets
kubectl get secret backend-secrets -n app-backend -o yaml
```

## Cost Optimization

### Azure Mode
- Use **Burstable** SKU for PostgreSQL in dev/staging
- Use **Basic** Redis tier for non-production
- Enable auto-shutdown for dev clusters
- Use **Spot Instances** for non-critical workloads

### On-Premise Mode
- Use smaller node sizes for dev/staging
- Reduce replica counts in non-production
- Use **node pools** with autoscaling
- Stop clusters during off-hours

## Security Best Practices

### Azure Mode
- ✅ Private endpoints for PostgreSQL and Redis (already configured)
- ✅ SSL/TLS encryption in transit (already configured)
- ✅ Azure Key Vault for secrets management (recommended)
- ✅ Managed identities for pod-to-Azure authentication
- ✅ Network security groups on subnets

### On-Premise Mode
- ✅ Network policies for pod communication (already configured)
- ✅ PVC encryption at rest
- ✅ Regular security patches for PostgreSQL/Redis images
- ✅ Resource quotas and limits
- ✅ Pod security policies

## Performance Tuning

### Azure Mode
- PostgreSQL: Adjust `max_connections`, `shared_buffers` via Azure Portal
- Redis: Use clustering for high throughput (Premium tier)
- Enable read replicas for PostgreSQL if needed

### On-Premise Mode
- PostgreSQL: Edit ConfigMap to tune parameters
- Redis: Increase memory limits in deployment
- Use node affinity to place DB pods on larger nodes

## Support and Documentation

- [Terraform README](infra/terraform/README.md)
- [Namespace Architecture](NAMESPACE_ARCHITECTURE.md)
- [CI/CD README](CICD_README.md)
- [Azure AKS Docs](https://docs.microsoft.com/en-us/azure/aks/)
- [PostgreSQL Flexible Server Docs](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Azure Cache for Redis Docs](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/)
