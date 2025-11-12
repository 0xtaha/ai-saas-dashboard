# Quick Start Guide - AI SaaS Dashboard

## Prerequisites Check

```bash
# Check required tools
az --version          # Azure CLI
terraform --version   # Terraform >= 1.5.0
kubectl version      # Kubernetes CLI
docker --version     # Docker
```

## 🚀 Fast Track Deployment

### Step 1: Choose Your Mode

**Azure Managed Services** (~$1,140/month)
- Best for: Production workloads
- Pros: Fully managed, HA, automated backups
- Cons: Higher cost

**On-Premise** (~$490/month)
- Best for: Development, testing, budget-conscious
- Pros: Lower cost, full control
- Cons: Manual management required

### Step 2: One-Command Deploy

#### Using Terraform (Recommended)

```bash
# Clone repository
git clone <repo-url>
cd ai-saas-dashboard

# Configure Terraform
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars - change deployment_mode to "azure" or "onprem"
nano terraform.tfvars

# Deploy infrastructure
terraform init
terraform apply -auto-approve

# Get credentials and deploy app
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)

cd ../../scripts/deploy
./deploy-with-mode.sh azure  # or onprem
```

#### Manual Deploy (Without Terraform)

```bash
# Create secrets
cd scripts/deploy
./create-secrets.sh

# Deploy with mode selection
./deploy-with-mode.sh azure  # or onprem
```

### Step 3: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n app-backend
kubectl get pods -n app-frontend
kubectl get pods -n shared

# Get external IP
kubectl get ingress -n app-frontend
```

## 📊 Common Commands

### Deployment

```bash
# Deploy/Update application
./scripts/deploy/deploy-with-mode.sh [azure|onprem]

# Check deployment status
kubectl rollout status deployment/backend -n app-backend
kubectl rollout status deployment/frontend -n app-frontend
```

### Monitoring

```bash
# View logs
kubectl logs -f deployment/backend -n app-backend
kubectl logs -f deployment/frontend -n app-frontend
kubectl logs -f daemonset/fluent-bit -n shared

# Access Prometheus
kubectl port-forward -n shared svc/prometheus-service 9090:9090
# Open: http://localhost:9090

# View metrics
kubectl top pods -n app-backend
kubectl top nodes
```

### Database Operations (On-Premise)

```bash
# Connect to PostgreSQL
kubectl exec -it -n app-backend <postgres-pod> -- psql -U postgres -d ai_saas_db

# Backup database
kubectl exec -n app-backend <postgres-pod> -- \
  pg_dump -U postgres ai_saas_db > backup-$(date +%Y%m%d).sql

# Restore database
kubectl exec -i -n app-backend <postgres-pod> -- \
  psql -U postgres -d ai_saas_db < backup.sql
```

### Scaling

```bash
# Scale backend
kubectl scale deployment/backend -n app-backend --replicas=5

# Scale frontend
kubectl scale deployment/frontend -n app-frontend --replicas=3

# Check HPA status
kubectl get hpa -n app-backend
```

### Troubleshooting

```bash
# Describe pod for issues
kubectl describe pod <pod-name> -n app-backend

# Get recent events
kubectl get events -n app-backend --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n app-backend

# View ConfigMaps
kubectl get configmap backend-config -n app-backend -o yaml

# Check secrets (base64 encoded)
kubectl get secret backend-secrets -n app-backend -o yaml
```

## 🔄 CI/CD via GitHub Actions

### Setup

1. Add secrets to GitHub repository:
   ```
   AZURE_CREDENTIALS
   AZURE_CONTAINER_REGISTRY
   AKS_CLUSTER_NAME
   AKS_RESOURCE_GROUP
   SECRET_KEY
   JWT_SECRET_KEY
   POSTGRES_PASSWORD
   DEPLOYMENT_MODE=azure  # or onprem
   ```

2. For Azure mode, also add:
   ```
   AZURE_POSTGRES_HOST
   AZURE_POSTGRES_PASSWORD
   AZURE_REDIS_HOST
   AZURE_REDIS_KEY
   ```

### Manual Trigger

1. Go to GitHub → Actions → CD - Deploy to Azure AKS
2. Click "Run workflow"
3. Select environment and deployment mode
4. Click "Run workflow"

### Automatic Deploy

Push to `main` branch triggers automatic deployment.

## 🔐 Security Quick Checks

```bash
# Check network policies
kubectl get networkpolicies -n app-backend

# Verify pod security
kubectl auth can-i list secrets -n app-backend --as=system:serviceaccount:app-backend:default

# Check RBAC
kubectl get rolebindings -n app-backend

# Scan images for vulnerabilities
az acr repository show-tags --name <acr-name> --repository ai-saas-backend
```

## 💰 Cost Management

### View Current Costs

```bash
# Azure CLI
az consumption usage list \
  --start-date $(date -d "30 days ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(name.value, 'ai-saas')]"
```

### Reduce Costs

**Azure Mode:**
```bash
# Scale down PostgreSQL (non-prod)
az postgres flexible-server update \
  --name <server-name> \
  --resource-group <rg> \
  --sku-name B_Standard_B1ms

# Scale down Redis (non-prod)
az redis update \
  --name <redis-name> \
  --resource-group <rg> \
  --sku Basic \
  --vm-size C1
```

**On-Premise Mode:**
```bash
# Reduce node count
az aks nodepool scale \
  --cluster-name <aks-name> \
  --resource-group <rg> \
  --name system \
  --node-count 1
```

## 🛠️ Maintenance

### Update Application

```bash
# Build new images
docker build -t <acr>.azurecr.io/ai-saas-backend:v2.0 ./backend
docker push <acr>.azurecr.io/ai-saas-backend:v2.0

# Update deployment
kubectl set image deployment/backend \
  backend=<acr>.azurecr.io/ai-saas-backend:v2.0 \
  -n app-backend

# Or use CI/CD workflow
```

### Backup Everything

```bash
# Backup Kubernetes manifests
kubectl get all -n app-backend -o yaml > backup-app-backend.yaml
kubectl get all -n app-frontend -o yaml > backup-app-frontend.yaml
kubectl get all -n shared -o yaml > backup-shared.yaml

# Backup secrets (encrypted)
kubectl get secrets --all-namespaces -o yaml > backup-secrets.yaml.enc
```

### Disaster Recovery

```bash
# Restore from backup
kubectl apply -f backup-app-backend.yaml
kubectl apply -f backup-app-frontend.yaml
kubectl apply -f backup-shared.yaml

# Or use Terraform
terraform apply
```

## 📱 Access Application

### Local Port Forward

```bash
# Access backend locally
kubectl port-forward -n app-backend svc/backend-service 5000:5000
# API: http://localhost:5000/api

# Access frontend locally
kubectl port-forward -n app-frontend svc/frontend-service 3000:80
# UI: http://localhost:3000

# Access Prometheus
kubectl port-forward -n shared svc/prometheus-service 9090:9090
# Prometheus: http://localhost:9090
```

### Production Access

```bash
# Get ingress IP
kubectl get ingress -n app-frontend

# Configure DNS (if using domain)
# Point your domain to the EXTERNAL-IP shown above
```

## 🆘 Emergency Procedures

### Application Down

```bash
# 1. Check pod status
kubectl get pods -n app-backend -n app-frontend

# 2. Check recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# 3. Restart deployments
kubectl rollout restart deployment/backend -n app-backend
kubectl rollout restart deployment/frontend -n app-frontend

# 4. Check logs
kubectl logs -f deployment/backend -n app-backend --tail=100
```

### Database Connection Issues

**On-Premise:**
```bash
# Check PostgreSQL pod
kubectl get pod -n app-backend -l app=postgres

# Restart PostgreSQL
kubectl rollout restart statefulset/postgres -n app-backend

# Check connectivity from backend
kubectl exec -n app-backend <backend-pod> -- \
  nc -zv postgres-service.app-backend.svc.cluster.local 5432
```

**Azure Mode:**
```bash
# Check Azure PostgreSQL status
az postgres flexible-server show \
  --name <server-name> \
  --resource-group <rg>

# Verify connectivity
kubectl exec -n app-backend <backend-pod> -- \
  nc -zv <postgres-fqdn> 5432
```

### Rollback Deployment

```bash
# View deployment history
kubectl rollout history deployment/backend -n app-backend

# Rollback to previous version
kubectl rollout undo deployment/backend -n app-backend

# Rollback to specific revision
kubectl rollout undo deployment/backend -n app-backend --to-revision=2
```

## 📚 Quick Reference Links

- [Full Deployment Modes Documentation](DEPLOYMENT_MODES.md)
- [Terraform Infrastructure Guide](infra/terraform/README.md)
- [Namespace Architecture](NAMESPACE_ARCHITECTURE.md)
- [CI/CD Documentation](CICD_README.md)

## 🎯 Next Steps

1. ✅ Set up monitoring alerts in Azure Monitor
2. ✅ Configure SSL certificates with cert-manager
3. ✅ Set up automated backups
4. ✅ Configure auto-scaling policies
5. ✅ Set up log retention policies
6. ✅ Configure disaster recovery procedures

## 💬 Support

For issues or questions:
- Check logs: `kubectl logs -f deployment/backend -n app-backend`
- Review events: `kubectl get events -n app-backend`
- Check pod status: `kubectl describe pod <pod-name> -n app-backend`
- Review Azure service health: Azure Portal → Service Health

---

**Deployment Mode:** Check with `kubectl get configmap backend-config -n app-backend -o yaml | grep DATABASE_HOST`
- Contains `.svc.cluster.local` = On-Premise Mode
- Contains `.azure.com` = Azure Managed Services Mode
