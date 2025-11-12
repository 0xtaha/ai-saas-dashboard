# Project Structure

## Complete Directory Layout

```
ai-saas-dashboard/
├── backend/                        # Flask Backend Application
│   ├── app/
│   │   ├── models/                # Database models
│   │   ├── routes/                # API endpoints
│   │   ├── services/              # Business logic
│   │   ├── utils/                 # Utilities
│   │   └── middleware/            # Custom middleware
│   ├── uploaded_files/            # File storage
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/                       # React Frontend Application
│   ├── src/
│   │   ├── components/            # Reusable components
│   │   ├── pages/                 # Page components
│   │   ├── services/              # API services
│   │   ├── contexts/              # React contexts
│   │   └── styles/                # CSS files
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── infra/                          # Infrastructure Code
│   ├── k8s/                       # Kubernetes Manifests
│   │   ├── namespaces/           # Namespace definitions
│   │   ├── base/                 # Base manifests
│   │   ├── overlays/             # Environment overlays
│   │   │   ├── azure/           # Azure managed services
│   │   │   └── onprem/          # On-premise mode
│   │   └── monitoring/           # Monitoring stack
│   │       ├── fluent-bit/
│   │       └── prometheus/
│   │
│   ├── terraform/                 # Terraform IaC
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── aks.tf
│   │   ├── postgres.tf
│   │   ├── redis.tf
│   │   └── ...
│   │
│   └── README.md                  # Infrastructure docs
│
├── scripts/                        # Deployment Scripts
│   └── deploy/
│       ├── create-secrets.sh
│       ├── deploy-manual.sh
│       ├── deploy-with-mode.sh
│       └── setup-azure.sh
│
├── .github/                        # GitHub Actions
│   └── workflows/
│       ├── ci.yml
│       └── cd.yml
│
├── docker-compose.yml              # Local development
├── docker-compose.prod.yml         # Production overrides
│
├── DEPLOYMENT_MODES.md             # Deployment modes guide
├── QUICK_START.md                  # Quick start guide
├── NAMESPACE_ARCHITECTURE.md       # Multi-namespace docs
├── CICD_README.md                  # CI/CD documentation
└── README.md                       # Main documentation
```

## Infrastructure Organization

All infrastructure-related code is now organized under the `infra/` directory:

### Kubernetes Manifests (`infra/k8s/`)

- **namespaces/** - Namespace definitions (app-backend, app-frontend, shared)
- **base/** - Base Kubernetes resources (deployments, services, ingress)
- **overlays/** - Kustomize overlays for different deployment modes
  - **azure/** - Azure managed services configuration
  - **onprem/** - On-premise configuration
- **monitoring/** - Monitoring stack (Fluent Bit, Prometheus)

### Terraform (`infra/terraform/`)

- Infrastructure as Code for Azure resources
- Supports both Azure and on-premise deployment modes
- Creates AKS, ACR, networking, and optionally PostgreSQL/Redis

## Key Paths

### Deployment Scripts

All deployment scripts reference the new structure:

```bash
# Deploy with mode
./scripts/deploy/deploy-with-mode.sh azure

# Manual deployment
./scripts/deploy/deploy-manual.sh

# Create secrets
./scripts/deploy/create-secrets.sh
```

### CI/CD Pipeline

GitHub Actions workflows automatically use `infra/k8s/` paths:

```yaml
kubectl apply -f infra/k8s/namespaces/
kubectl apply -f infra/k8s/base/
kubectl apply -f infra/k8s/monitoring/
```

### Kustomize

Kustomize overlays use relative paths:

```bash
# Azure mode
kustomize build infra/k8s/overlays/azure | kubectl apply -f -

# On-premise mode
kustomize build infra/k8s/overlays/onprem | kubectl apply -f -
```

## Migration Notes

If you have existing deployments, update your local scripts:

**Old Path:**
```bash
kubectl apply -f k8s/base/backend-deployment.yaml
```

**New Path:**
```bash
kubectl apply -f infra/k8s/base/backend-deployment.yaml
```

**Kustomize:**
```bash
# Old
cd k8s/overlays/azure

# New
cd infra/k8s/overlays/azure
```

## Benefits of New Structure

1. **Better Organization** - All infrastructure code in one place
2. **Clear Separation** - Application code vs infrastructure code
3. **Easier Navigation** - Related files grouped together
4. **Professional Structure** - Follows industry best practices
5. **Scalability** - Easy to add more infrastructure types

## Documentation

- [Infrastructure README](infra/README.md) - Infrastructure overview
- [Terraform Guide](infra/terraform/README.md) - Terraform documentation
- [Deployment Modes](DEPLOYMENT_MODES.md) - Deployment options
- [Quick Start](QUICK_START.md) - Getting started guide

---

**Last Updated:** 2025-01-12
