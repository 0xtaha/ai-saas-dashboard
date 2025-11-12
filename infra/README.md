# Infrastructure Directory

This directory contains all infrastructure-related code for the AI SaaS Dashboard, including Kubernetes manifests and Terraform configurations.

## Directory Structure

```
infra/
├── k8s/                          # Kubernetes manifests
│   ├── namespaces/              # Namespace definitions
│   │   └── namespaces.yaml      # app-backend, app-frontend, shared
│   ├── base/                    # Base Kubernetes resources
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── postgres-deployment.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   ├── overlays/                # Environment-specific configs
│   │   ├── azure/               # Azure managed services mode
│   │   │   ├── backend-config.yaml
│   │   │   ├── backend-patch.yaml
│   │   │   ├── azure-secrets.yaml
│   │   │   └── kustomization.yaml
│   │   └── onprem/              # On-premise mode
│   │       ├── backend-config.yaml
│   │       └── kustomization.yaml
│   └── monitoring/              # Monitoring stack
│       ├── fluent-bit/          # Log aggregation
│       │   ├── rbac.yaml
│       │   ├── configmap.yaml
│       │   └── daemonset.yaml
│       └── prometheus/          # Metrics collection
│           ├── rbac.yaml
│           ├── configmap.yaml
│           ├── deployment.yaml
│           └── servicemonitors.yaml
│
└── terraform/                   # Infrastructure as Code
    ├── main.tf                  # Provider configuration
    ├── variables.tf             # Input variables
    ├── outputs.tf               # Output values
    ├── resource-group.tf        # Azure resource group
    ├── networking.tf            # VNet, subnets, NSG
    ├── aks.tf                   # AKS cluster
    ├── acr.tf                   # Container Registry
    ├── postgres.tf              # Azure PostgreSQL (Azure mode)
    ├── redis.tf                 # Azure Redis (Azure mode)
    ├── monitoring.tf            # Log Analytics, App Insights
    ├── kubernetes-config.tf     # K8s resources
    ├── terraform.tfvars.example # Example configuration
    └── README.md                # Terraform documentation
```

## Quick Start

### Deploy with Terraform

```bash
# Navigate to terraform directory
cd infra/terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your configuration
nano terraform.tfvars

# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan

# Apply infrastructure
terraform apply
```

### Deploy Kubernetes Manifests

#### Using kubectl (On-Premise Mode)

```bash
# Create namespaces
kubectl apply -f infra/k8s/namespaces/

# Deploy backend infrastructure
kubectl apply -f infra/k8s/base/postgres-deployment.yaml
kubectl apply -f infra/k8s/base/redis-deployment.yaml

# Deploy applications
kubectl apply -f infra/k8s/base/backend-deployment.yaml
kubectl apply -f infra/k8s/base/frontend-deployment.yaml

# Deploy monitoring
kubectl apply -f infra/k8s/monitoring/fluent-bit/
kubectl apply -f infra/k8s/monitoring/prometheus/

# Deploy ingress
kubectl apply -f infra/k8s/base/ingress.yaml
```

#### Using Kustomize (Recommended)

**Azure Mode:**
```bash
cd infra/k8s/overlays/azure
kustomize build . | kubectl apply -f -
```

**On-Premise Mode:**
```bash
cd infra/k8s/overlays/onprem
kustomize build . | kubectl apply -f -
```

### Using Deployment Scripts

```bash
# From project root
cd scripts/deploy

# Azure mode with Terraform outputs
./deploy-with-mode.sh azure

# On-premise mode
./deploy-with-mode.sh onprem
```

## Kubernetes Resources

### Namespaces

| Namespace | Purpose | Resources |
|-----------|---------|-----------|
| `app-backend` | Backend API, Database, Cache | Backend API, PostgreSQL, Redis (onprem) |
| `app-frontend` | React Frontend | Frontend app, Nginx |
| `shared` | Monitoring & Observability | Fluent Bit, Prometheus |

### Base Manifests

Located in `k8s/base/`:

- **backend-deployment.yaml** - Backend API deployment with ConfigMap and Service
- **frontend-deployment.yaml** - Frontend deployment with ConfigMap and Service
- **postgres-deployment.yaml** - PostgreSQL StatefulSet (on-premise mode)
- **redis-deployment.yaml** - Redis deployment (on-premise mode)
- **ingress.yaml** - NGINX Ingress for frontend and monitoring

### Overlays

#### Azure Overlay (`k8s/overlays/azure/`)

Configures the application to use Azure managed services:
- Azure Database for PostgreSQL Flexible Server
- Azure Cache for Redis Premium
- Private endpoint connections
- SSL/TLS required

#### On-Premise Overlay (`k8s/overlays/onprem/`)

Configures the application for in-cluster services:
- PostgreSQL pods with persistent volumes
- Redis pods
- Standard Kubernetes service discovery

### Monitoring Stack

#### Fluent Bit (`k8s/monitoring/fluent-bit/`)

DaemonSet that runs on every node to collect logs:
- Collects container logs from all pods
- Enriches with Kubernetes metadata
- Filters by namespace (app-backend, app-frontend, shared)
- Ships to Azure Log Analytics

#### Prometheus (`k8s/monitoring/prometheus/`)

Metrics collection and alerting:
- Scrapes metrics from backend, frontend, and monitoring pods
- 50GB persistent storage for metrics
- Pre-configured alerting rules
- ServiceMonitors for auto-discovery

## Terraform Resources

### Core Infrastructure

| Resource | Purpose | SKU/Size |
|----------|---------|----------|
| AKS Cluster | Container orchestration | 3 node pools |
| ACR | Container registry | Premium |
| VNet | Network isolation | 10.0.0.0/16 |
| Log Analytics | Centralized logging | PerGB2018 |

### Azure Mode Resources

Only created when `deployment_mode = "azure"`:

| Resource | Purpose | Configuration |
|----------|---------|---------------|
| PostgreSQL Flexible Server | Application database | GP_Standard_D4s_v3 |
| Redis Cache | Session/caching | Premium P1 |
| Private DNS Zones | Private endpoints | Auto-configured |
| VNet Integration | Private connectivity | Delegated subnets |

### Variables

Key Terraform variables:

```hcl
deployment_mode = "azure"  # or "onprem"
project_name    = "ai-saas-dashboard"
environment     = "prod"
location        = "East US"
```

See [terraform/README.md](terraform/README.md) for full documentation.

## Deployment Modes

### Azure Managed Services Mode

**Pros:**
- Fully managed database and cache
- Built-in high availability (zone-redundant)
- Automated backups (7-day retention)
- Scaling without pod restarts
- Better performance (dedicated resources)

**Cons:**
- Higher cost (~$1,140/month)
- Requires VNet integration
- Additional Azure resources to manage

### On-Premise Mode

**Pros:**
- Lower cost (~$490/month)
- Full control over database/cache
- Simpler networking (no private endpoints)
- Suitable for dev/test environments

**Cons:**
- Manual backup configuration required
- Limited high availability options
- Scaling requires pod restarts
- Shared resources with AKS nodes

## Configuration

### Environment-Specific ConfigMaps

**Azure Mode:**
```yaml
DATABASE_HOST: <server>.postgres.database.azure.com
DATABASE_SSL_MODE: require
REDIS_HOST: <cache>.redis.cache.windows.net
REDIS_SSL: "true"
```

**On-Premise Mode:**
```yaml
DATABASE_HOST: postgres-service.app-backend.svc.cluster.local
DATABASE_SSL_MODE: prefer
REDIS_HOST: redis-service.app-backend.svc.cluster.local
REDIS_SSL: "false"
```

### Secrets Management

Secrets are created per namespace:

```bash
# Backend secrets (app-backend namespace)
kubectl create secret generic backend-secrets \
  --from-literal=SECRET_KEY=... \
  --from-literal=JWT_SECRET_KEY=... \
  --from-literal=POSTGRES_PASSWORD=... \
  --namespace=app-backend

# Monitoring secrets (shared namespace)
kubectl create secret generic monitoring-secrets \
  --from-literal=WORKSPACE_ID=... \
  --from-literal=WORKSPACE_KEY=... \
  --namespace=shared
```

Use the provided script:
```bash
../../scripts/deploy/create-secrets.sh
```

## Monitoring

### Access Prometheus

```bash
kubectl port-forward -n shared svc/prometheus-service 9090:9090
```
Open: http://localhost:9090

### View Logs in Azure Log Analytics

Navigate to Azure Portal → Log Analytics Workspace → Logs

Sample query:
```kusto
KubernetesLogs
| where Namespace in ("app-backend", "app-frontend", "shared")
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
```

### Metrics Endpoints

- Backend: `http://backend-service.app-backend.svc.cluster.local:5000/metrics`
- Prometheus: `http://prometheus-service.shared.svc.cluster.local:9090`
- Fluent Bit: `http://fluent-bit.shared.svc.cluster.local:2020/api/v1/metrics/prometheus`

## Maintenance

### Update Kubernetes Manifests

```bash
# Edit manifests
nano infra/k8s/base/backend-deployment.yaml

# Apply changes
kubectl apply -f infra/k8s/base/backend-deployment.yaml
```

### Update Terraform Infrastructure

```bash
cd infra/terraform

# Edit configuration
nano variables.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Backup

#### Kubernetes Manifests
```bash
kubectl get all -n app-backend -o yaml > backup-backend.yaml
kubectl get all -n app-frontend -o yaml > backup-frontend.yaml
kubectl get all -n shared -o yaml > backup-shared.yaml
```

#### Terraform State
```bash
cd infra/terraform
terraform state pull > terraform.tfstate.backup
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n app-backend
kubectl get pods -n app-frontend
kubectl get pods -n shared
```

### View Logs

```bash
kubectl logs -f deployment/backend -n app-backend
kubectl logs -f deployment/frontend -n app-frontend
kubectl logs -f daemonset/fluent-bit -n shared
```

### Describe Resources

```bash
kubectl describe pod <pod-name> -n app-backend
kubectl describe deployment backend -n app-backend
```

### Check Events

```bash
kubectl get events -n app-backend --sort-by='.lastTimestamp'
```

## Related Documentation

- [Terraform Infrastructure Guide](terraform/README.md)
- [Deployment Modes Guide](../DEPLOYMENT_MODES.md)
- [Namespace Architecture](../NAMESPACE_ARCHITECTURE.md)
- [Quick Start Guide](../QUICK_START.md)
- [CI/CD Documentation](../CICD_README.md)

## Support

For infrastructure-related issues:
1. Check pod status and logs
2. Review Terraform state
3. Check Azure service health
4. Review deployment documentation

---

**Last Updated:** 2025-01-12
