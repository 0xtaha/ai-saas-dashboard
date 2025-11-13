# AI SaaS Dashboard

A production-ready, enterprise-grade AI-powered file processing platform with multi-deployment support for Azure managed services and on-premise infrastructure.

## 🌟 Features

- **User Authentication** - Secure JWT-based authentication with session management
- **File Upload** - Drag-and-drop file uploads with SHA-256 checksum-based deduplication
- **Dual Storage Modes** - Azure Blob Storage (managed) or Persistent Volumes (on-premise)
- **AI Processing** - Automatic file processing with AI integration and status tracking
- **Results Visualization** - Interactive display of processing results with mock data fallback
- **File Management** - List, view, and delete uploaded files with pagination
- **Multi-Namespace Architecture** - Separate namespaces for backend, frontend, and monitoring
- **Dual Deployment Modes** - Support for both Azure managed services and on-premise deployments
- **Comprehensive Monitoring** - Fluent Bit + Prometheus + Azure Log Analytics
- **CI/CD Pipeline** - GitHub Actions with automated deployment to Azure AKS
- **Infrastructure as Code** - Complete Terraform configuration for Azure resources

## 🏗️ Architecture

### Deployment Modes

#### Azure Managed Services Mode
- **Azure Kubernetes Service (AKS)** - Container orchestration
- **Azure Database for PostgreSQL Flexible Server** - Managed database with HA
- **Azure Cache for Redis Premium** - Managed caching with clustering
- **Azure Blob Storage** - Managed file storage with lifecycle policies
- **Azure Container Registry** - Private container registry
- **Azure Log Analytics** - Centralized logging and monitoring
- **Cost:** ~$1,140/month + storage costs

#### Pure On-Premise Mode (Zero Azure Dependencies)
- **Any Kubernetes** - K3s, RKE2, kubeadm, or any K8s distribution
- **PostgreSQL in-cluster** - Self-hosted database with persistent volumes
- **Redis in-cluster** - Self-hosted cache
- **Flexible Storage** - Local-path, NFS, Longhorn, Ceph/Rook, or any storage provisioner
- **Harbor/Docker Registry** - On-premise container registry with scanning
- **Loki/ELK Stack** - On-premise logging (no cloud dependencies)
- **Prometheus + Grafana** - Full observability stack
- **Cost:** ~$490/month (infrastructure) or one-time hardware cost
- **Data Sovereignty**: Complete control, air-gap capable

### Tech Stack

**Frontend**
- React 18 with React Router 6
- Axios for API communication
- Context API for state management
- Nginx for production hosting
- Responsive design with CSS3

**Backend**
- Flask 3.0 with SQLAlchemy ORM
- PostgreSQL 15 with connection pooling
- Redis for caching and sessions ( Not used yet )
- JWT authentication with Flask-JWT-Extended
- Flask-Migrate for database migrations
- Azure Blob Storage SDK (dual storage support)
- Gunicorn WSGI server


**Monitoring & Observability** ( setup not fully supported )
- Fluent Bit for log aggregation
- Prometheus for metrics collection 
- Azure Log Analytics for centralized logs
- Application Insights for APM
- Grafana dashboards (optional)

## 📁 Project Structure

```
ai-saas-dashboard/
├── frontend/                       # React frontend application
│   ├── src/
│   │   ├── components/            # Reusable components
│   │   │   ├── FileUpload.js
│   │   │   ├── FileList.js
│   │   │   └── ProcessingResults.js
│   │   ├── pages/                 # Page components
│   │   │   ├── Dashboard.js
│   │   │   ├── Login.js
│   │   │   └── Register.js
│   │   ├── services/              # API service layer
│   │   ├── contexts/              # React contexts
│   │   └── styles/                # CSS modules
│   ├── Dockerfile                 # Multi-stage build
│   ├── nginx.conf                 # Nginx configuration
│   └── package.json
│
├── backend/                        # Flask backend API
│   ├── app/
│   │   ├── models/                # SQLAlchemy models
│   │   │   ├── user.py
│   │   │   ├── file.py
│   │   │   └── ai_request.py
│   │   ├── routes/                # API endpoints
│   │   │   ├── auth.py
│   │   │   ├── files.py
│   │   │   └── health.py
│   │   ├── services/              # Business logic
│   │   │   ├── file_service.py
│   │   │   └── ai_service.py
│   │   ├── utils/                 # Utility functions
│   │   └── middleware/            # Custom middleware
│   ├── uploaded_files/            # File storage directory
│   ├── Dockerfile
│   └── requirements.txt
│
├── infra/k8s/                            # Kubernetes manifests
│   ├── namespaces/
│   │   └── namespaces.yaml        # 3 namespaces definition
│   ├── base/                      # Base manifests
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── postgres-deployment.yaml
│   │   ├── redis-deployment.yaml
│   │   └── ingress.yaml
│   ├── overlays/                  # Environment overlays
│   │   ├── azure/                 # Azure managed services
│   │   │   ├── backend-config.yaml
│   │   │   ├── backend-patch.yaml
│   │   │   └── kustomization.yaml
│   │   └── onprem/                # On-premise mode
│   │       ├── backend-config.yaml
│   │       └── kustomization.yaml
│   └── monitoring/                # Monitoring stack
│       ├── fluent-bit/
│       │   ├── configmap.yaml
│       │   ├── daemonset.yaml
│       │   └── rbac.yaml
│       └── prometheus/
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── rbac.yaml
│           └── servicemonitors.yaml
│
├── infra/                          # Infrastructure as Code
│   └── terraform/
│       ├── shared/                # Common configurations
│       │   ├── variables.tf       # Shared variables
│       │   └── outputs.tf         # Shared outputs
│       ├── azure/                 # Azure deployment
│       │   ├── main.tf            # Azure provider config
│       │   ├── variables.tf       # Azure-specific variables
│       │   ├── aks.tf             # AKS cluster
│       │   ├── postgres.tf        # Azure PostgreSQL
│       │   ├── redis.tf           # Azure Redis
│       │   ├── monitoring.tf      # Log Analytics, App Insights
│       │   └── networking.tf      # VNet, subnets, NSG
│       ├── onprem/                # On-premise deployment
│       │   ├── main.tf            # Kubernetes provider config
│       │   ├── variables.tf       # On-premise variables
│       │   ├── namespaces.tf      # Namespace resources
│       │   ├── storage.tf         # Storage classes, PVCs
│       │   ├── postgres.tf        # In-cluster PostgreSQL
│       │   ├── redis.tf           # In-cluster Redis
│       │   ├── registry.tf        # Container registry
│       │   └── monitoring.tf      # Prometheus, Loki, Grafana
│       └── README.md              # Terraform documentation
│
├── .github/                        # GitHub Actions workflows
│   └── workflows/
│       ├── ci.yml                 # Continuous Integration
│       └── cd.yml                 # Continuous Deployment
│
├── scripts/                        # Deployment scripts
│   └── deploy/
│       ├── create-secrets.sh      # Create K8s secrets
│       ├── deploy-manual.sh       # Manual deployment
│       ├── deploy-with-mode.sh    # Mode-aware deployment
│       └── setup-azure.sh         # Azure resource setup
│
├── docs/                           # Documentation
│   ├── ARCHITECTURE_AZURE.md      # Azure architecture guide
│   ├── ARCHITECTURE_ONPREMISE.md  # On-premise architecture guide
│   ├── CICD_README.md             # CI/CD documentation
│   ├── DEPLOYMENT_MODES.md        # Deployment modes guide
│   ├── DOCKER_GUIDE.md            # Docker development guide
│   ├── MIGRATION_GUIDE.md         # Migration guide
│   ├── NAMESPACE_ARCHITECTURE.md  # Multi-namespace docs
│   ├── QUICK_START.md             # Quick start guide
│   ├── QUICKSTART_CICD.md         # CI/CD quick start
│   ├── RELEASE_PROCESS.md         # Release and tagging strategy
│   └── STRUCTURE.md               # Project structure details
│
├── docker-compose.yml             # Local development
├── docker-compose.prod.yml        # Production overrides
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites
- Azure CLI (`az`)
- Terraform (>= 1.5.0)
- kubectl
- Docker & Docker Compose
- Git

### Option 1: Terraform Deployment (Recommended)

```bash
# 1. Clone repository
git clone <repository-url>
cd ai-saas-dashboard

# 2. Configure Terraform
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars - set deployment_mode to "azure" or "onprem"
nano terraform.tfvars

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 4. Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)

# 5. Deploy application
cd ../../scripts/deploy
./deploy-with-mode.sh azure  # or onprem
```

### Option 2: Local Development with Docker Compose

```bash
# 1. Clone and setup
git clone <repository-url>
cd ai-saas-dashboard
cp .env.example .env

# 2. Edit .env with your configuration

# 3. Start services
docker-compose up --build

# 4. Initialize database
docker-compose exec backend python scripts/init_db.py
```

Access the application:
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:5000/api
- **API Docs:** http://localhost:5000/api/docs

## 📚 Documentation

### Getting Started
- **[Quick Start Guide](docs/QUICK_START.md)** - Get started quickly with common commands
- **[CI/CD Quick Start](docs/QUICKSTART_CICD.md)** - Fast-track CI/CD setup
- **[Docker Development Guide](docs/DOCKER_GUIDE.md)** - Local development with Docker Compose

### Deployment & Operations
- **[Branching Strategy](BRANCHING_STRATEGY.md)** - Complete branching workflow and CI/CD integration guide
- **[On-Premise Deployment](docs/ONPREMISE_DEPLOYMENT.md)** - 🆕 Complete guide for pure on-premise deployment (zero Azure dependencies)
- **[On-Premise Migration Summary](ONPREMISE_MIGRATION_SUMMARY.md)** - 🆕 Quick reference for on-premise setup
- **[Deployment Modes](docs/DEPLOYMENT_MODES.md)** - Detailed comparison of Azure vs On-Premise modes
- **[Release Process](docs/RELEASE_PROCESS.md)** - Git tagging strategy and deployment workflow
- **[Migration Guide](docs/MIGRATION_GUIDE.md)** - Migrating between deployment modes

### Architecture & Design
- **[Azure Architecture](docs/ARCHITECTURE_AZURE.md)** - Complete Azure managed services architecture with diagrams
- **[On-Premise Architecture](docs/ARCHITECTURE_ONPREMISE.md)** - Platform-independent in-cluster deployment architecture
- **[Namespace Architecture](docs/NAMESPACE_ARCHITECTURE.md)** - Multi-namespace design patterns
- **[Project Structure](docs/STRUCTURE.md)** - Detailed project organization

### Infrastructure & CI/CD
- **[Terraform Infrastructure](infra/terraform/README.md)** - Infrastructure as Code documentation
- **[CI/CD Pipeline](docs/CICD_README.md)** - Complete GitHub Actions workflow guide
- **[CI/CD Flow Diagrams](docs/CICD_FLOW_DIAGRAM.md)** - Visual Mermaid diagrams of the complete pipeline

## 🔧 Configuration

### Environment Variables

#### Backend Configuration

**Azure Mode:**
```env
DATABASE_HOST=<server>.postgres.database.azure.com
DATABASE_PORT=5432
DATABASE_SSL_MODE=require
REDIS_HOST=<cache>.redis.cache.windows.net
REDIS_PORT=6380
REDIS_SSL=true
```

**On-Premise Mode:**
```env
DATABASE_HOST=postgres-service.app-backend.svc.cluster.local
DATABASE_PORT=5432
DATABASE_SSL_MODE=prefer
REDIS_HOST=redis-service.app-backend.svc.cluster.local
REDIS_PORT=6379
REDIS_SSL=false
```

**CORS Configuration:**
```env
# For development (allows all origins)
CORS_ORIGINS=*

# For production (specific frontend URLs)
CORS_ORIGINS=https://app.example.com,https://www.example.com
```

### GitHub Secrets

Required secrets for CI/CD:
```
AZURE_CREDENTIALS
AZURE_CONTAINER_REGISTRY
AKS_CLUSTER_NAME
AKS_RESOURCE_GROUP
SECRET_KEY
JWT_SECRET_KEY
POSTGRES_PASSWORD
DEPLOYMENT_MODE (azure|onprem)
```

For Azure mode, also add:
```
AZURE_POSTGRES_HOST
AZURE_POSTGRES_PASSWORD
AZURE_REDIS_HOST
AZURE_REDIS_KEY
```

## 📊 Monitoring

### Prometheus Metrics
```bash
kubectl port-forward -n shared svc/prometheus-service 9090:9090
# Access: http://localhost:9090
```

### Fluent Bit Logs
Logs are automatically shipped to Azure Log Analytics. Query in Azure Portal:
```kusto
KubernetesLogs
| where Namespace in ("app-backend", "app-frontend", "shared")
| order by TimeGenerated desc
```

### Application Insights
View APM data in Azure Portal → Application Insights

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest --cov=app
```

### Frontend Tests
```bash
cd frontend
npm test
npm run test:coverage
```

## 🔐 Security Features

- **Authentication:** JWT-based with secure token storage
- **Authorization:** Role-based access control (RBAC)
- **Network Security:** Network policies for pod-to-pod communication
- **Data Encryption:**
  - In transit: TLS/SSL for all connections
  - At rest: Encrypted persistent volumes
- **Secrets Management:** Kubernetes secrets with optional Azure Key Vault
- **Container Security:** Non-root containers, security contexts, image scanning
- **API Security:** Rate limiting, CORS, input validation

## 📈 Scaling

### Horizontal Pod Autoscaling
```bash
# Backend scales based on CPU/memory
kubectl get hpa -n app-backend

# Frontend scales based on CPU
kubectl get hpa -n app-frontend
```

### Database Scaling

**Azure Mode:** Scale via Azure Portal or CLI
```bash
az postgres flexible-server update \
  --name <server> --resource-group <rg> \
  --sku-name GP_Standard_D8s_v3
```

**On-Premise Mode:** Increase resources in deployment
```bash
kubectl scale statefulset/postgres -n app-backend --replicas=3
```

## 🛠️ Common Operations

### View Logs
```bash
# Backend logs
kubectl logs -f deployment/backend -n app-backend

# Frontend logs
kubectl logs -f deployment/frontend -n app-frontend

# Monitoring logs
kubectl logs -f daemonset/fluent-bit -n shared
```

### Database Backup (On-Premise)
```bash
kubectl exec -n app-backend <postgres-pod> -- \
  pg_dump -U postgres ai_saas_db > backup-$(date +%Y%m%d).sql
```

### Rollback Deployment
```bash
kubectl rollout undo deployment/backend -n app-backend
kubectl rollout undo deployment/frontend -n app-frontend
```

### Scale Applications
```bash
kubectl scale deployment/backend -n app-backend --replicas=5
kubectl scale deployment/frontend -n app-frontend --replicas=3
```

## 💰 Cost Optimization

### Azure Mode
- Use Burstable PostgreSQL SKU for dev/staging
- Use Basic Redis tier for non-production
- Enable AKS cluster auto-shutdown for dev
- Use spot instances for non-critical workloads

### On-Premise Mode
- Reduce node count during off-hours
- Use smaller VM sizes for dev/staging
- Implement pod resource limits
- Use node pool auto-scaling

## 🆘 Troubleshooting

### Application Issues
```bash
# Check pod status
kubectl get pods -n app-backend

# Describe pod for details
kubectl describe pod <pod-name> -n app-backend

# Check events
kubectl get events -n app-backend --sort-by='.lastTimestamp'
```

### Database Connection Issues
```bash
# Test connectivity
kubectl exec -n app-backend <backend-pod> -- \
  nc -zv <db-host> 5432

# Check logs
kubectl logs -n app-backend <backend-pod> | grep -i database
```

### Ingress Issues
```bash
# Check ingress status
kubectl get ingress -n app-frontend
kubectl describe ingress app-ingress -n app-frontend

# Check nginx ingress controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 👥 Support

- **Documentation:** See [`docs/`](docs/) folder for comprehensive guides
- **Issues:** Report bugs via GitHub Issues
- **Discussions:** Use GitHub Discussions for questions
- **Email:** support@example.com

### Documentation Index
All documentation is available in the [`docs/`](docs/) directory:
- Architecture guides (Azure & On-Premise)
- Deployment and operations guides
- CI/CD pipeline documentation
- Quick start and migration guides

## 🗺️ Roadmap

- [ ] GraphQL API support
- [ ] Real-time websocket notifications
- [ ] Multi-tenancy support
- [ ] Advanced RBAC with fine-grained permissions
- [ ] Integration with Azure AD for SSO
- [ ] Kubernetes Operator for automated operations
- [ ] Grafana dashboards for monitoring
- [ ] Automated disaster recovery procedures
- [ ] Multi-region deployment support
- [ ] Advanced AI model management

## 🙏 Acknowledgments

- Azure Kubernetes Service team for excellent documentation
- Flask and React communities
- Terraform providers and community modules
- Prometheus and Fluent Bit projects

---

**Deployment Status:** Check deployment mode with:
```bash
kubectl get configmap backend-config -n app-backend -o yaml | grep DATABASE_HOST
```

**Version:** 1.0.0
**Last Updated:** 2025-01-12
