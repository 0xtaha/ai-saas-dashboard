# Quick Start: CI/CD Deployment

Get your AI SaaS Dashboard deployed to Azure AKS in minutes!

## 🚀 5-Minute Setup

### Prerequisites Checklist

- [ ] Azure account with active subscription
- [ ] GitHub repository (forked or cloned)
- [ ] Azure CLI installed
- [ ] kubectl installed

### Step 1: Setup Azure (15 mins)

```bash
# Login to Azure
az login

# Run automated setup
chmod +x scripts/deploy/setup-azure.sh
./scripts/deploy/setup-azure.sh
```

**What this does:**
- Creates Azure Resource Group
- Sets up Azure Container Registry
- Creates AKS Cluster with autoscaling
- Installs NGINX Ingress Controller
- Configures SSL with cert-manager

**Save the output!** You'll need:
- ACR Username
- ACR Password
- External IP address

### Step 2: Configure GitHub Secrets (5 mins)

Go to: `Settings → Secrets and variables → Actions → New repository secret`

**Required Secrets:**

```bash
# Azure credentials (from Step 1 service principal creation)
AZURE_CREDENTIALS: <service-principal-json>

# ACR credentials (from Step 1 output)
AZURE_CONTAINER_REGISTRY: aisaasacr
ACR_USERNAME: <acr-username>
ACR_PASSWORD: <acr-password>

# AKS details
AKS_CLUSTER_NAME: ai-saas-aks
AKS_RESOURCE_GROUP: ai-saas-rg

# Application secrets (generate new ones!)
SECRET_KEY: <openssl rand -hex 32>
JWT_SECRET_KEY: <openssl rand -hex 32>
POSTGRES_PASSWORD: <openssl rand -hex 16>

# AI API (your provider)
AI_API_URL: https://your-ai-api.com
AI_API_KEY: your-api-key
```

### Step 3: Deploy! (2 mins)

**Option A: Automatic (Recommended)**

```bash
# Push to main branch
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will automatically:
✅ Run tests
✅ Build Docker images
✅ Push to ACR
✅ Deploy to AKS

**Option B: Manual**

```bash
# Create secrets in Kubernetes
./scripts/deploy/create-secrets.sh

# Deploy manually
export ACR_NAME=aisaasacr
export IMAGE_TAG=latest
./scripts/deploy/deploy-manual.sh
```

### Step 4: Configure DNS (5 mins)

```bash
# Get external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Create DNS A record
# your-domain.com → <EXTERNAL_IP>
```

Update `k8s/base/ingress.yaml`:
```yaml
- host: your-domain.com  # Change this
```

### Step 5: Verify Deployment (2 mins)

```bash
# Check pods
kubectl get pods -n ai-saas-dashboard

# Check services
kubectl get svc -n ai-saas-dashboard

# View logs
kubectl logs -f deployment/backend -n ai-saas-dashboard
```

**Access your app:**
- Via IP: `http://<EXTERNAL_IP>`
- Via Domain: `https://your-domain.com` (after DNS propagation)

## 📋 Command Cheat Sheet

### Common Operations

```bash
# View deployment status
kubectl get all -n ai-saas-dashboard

# View logs
kubectl logs -f deployment/backend -n ai-saas-dashboard
kubectl logs -f deployment/frontend -n ai-saas-dashboard

# Scale manually
kubectl scale deployment backend --replicas=5 -n ai-saas-dashboard

# Rollback deployment
kubectl rollout undo deployment/backend -n ai-saas-dashboard

# Port forward (for testing)
kubectl port-forward service/backend-service 5000:5000 -n ai-saas-dashboard
kubectl port-forward service/frontend-service 3000:80 -n ai-saas-dashboard

# Update secrets
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY="new-secret" \
  --namespace=ai-saas-dashboard \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/backend -n ai-saas-dashboard
```

### Monitoring

```bash
# Watch deployment progress
kubectl rollout status deployment/backend -n ai-saas-dashboard -w

# Get events
kubectl get events -n ai-saas-dashboard --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n ai-saas-dashboard
kubectl top nodes

# Describe pod
kubectl describe pod <pod-name> -n ai-saas-dashboard
```

### Debugging

```bash
# Execute shell in pod
kubectl exec -it <pod-name> -n ai-saas-dashboard -- /bin/bash

# View previous logs (if crashed)
kubectl logs <pod-name> -n ai-saas-dashboard --previous

# Copy files from pod
kubectl cp <pod-name>:/path/to/file ./local-file -n ai-saas-dashboard
```

## 🔄 CI/CD Workflow

### Development Flow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes and commit
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# 3. Create Pull Request
# → GitHub Actions runs CI tests

# 4. Merge to main
# → GitHub Actions automatically deploys to AKS
```

### Deployment Triggers

| Action | Trigger | Environment | Replicas |
|--------|---------|-------------|----------|
| Pull Request | CI tests only | N/A | N/A |
| Push to develop | CI tests only | N/A | N/A |
| Push to main | CI + Deploy | Staging | 2-3 |
| Release tag (v1.0.0) | CI + Deploy | Production | 3-10 |
| Manual dispatch | CI + Deploy | Selected | Custom |

## 🛠️ Troubleshooting

### Pods not starting?

```bash
# Check pod status
kubectl get pods -n ai-saas-dashboard

# View pod events
kubectl describe pod <pod-name> -n ai-saas-dashboard

# Check logs
kubectl logs <pod-name> -n ai-saas-dashboard
```

**Common issues:**
- **ImagePullBackOff**: Check ACR credentials
- **CrashLoopBackOff**: Check database connection, env vars
- **Pending**: Check node resources

### Can't access application?

```bash
# Check ingress
kubectl get ingress -n ai-saas-dashboard

# Check services
kubectl get svc -n ai-saas-dashboard

# Test locally via port-forward
kubectl port-forward service/frontend-service 8080:80 -n ai-saas-dashboard
```

### Database issues?

```bash
# Check PostgreSQL pod
kubectl get pod -l app=postgres -n ai-saas-dashboard

# Check PostgreSQL logs
kubectl logs -f deployment/postgres -n ai-saas-dashboard

# Test connection
kubectl exec -it <backend-pod> -n ai-saas-dashboard -- \
  python -c "from app import create_app; app = create_app(); print('DB OK')"
```

### GitHub Actions failing?

1. Check workflow logs in **Actions** tab
2. Verify all secrets are set correctly
3. Check Azure permissions
4. Enable debug logging: Set `ACTIONS_STEP_DEBUG=true` in secrets

## 📊 Monitoring Dashboard

### View in Azure Portal

1. Go to: **Azure Portal → Kubernetes services**
2. Select your cluster: `ai-saas-aks`
3. Click: **Workloads** to see deployments
4. Click: **Services and ingresses**
5. Click: **Logs** for Azure Monitor

### View in kubectl

```bash
# Dashboard (requires metrics-server)
kubectl proxy
# Visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# Or install k9s for terminal UI
brew install k9s  # Mac
# Run: k9s -n ai-saas-dashboard
```

## 🔐 Security Checklist

- [ ] Changed all default secrets
- [ ] SSL/TLS configured with cert-manager
- [ ] Network policies enabled
- [ ] RBAC configured
- [ ] Regular security scans enabled
- [ ] Secrets rotated regularly
- [ ] Container image scanning enabled
- [ ] Resource limits set

## 💰 Cost Optimization

**Current setup costs** (East US, approximate):
- AKS Cluster: ~$70/month (3 Standard_D2s_v3 nodes)
- Container Registry: ~$5/month (Standard tier)
- Load Balancer: ~$20/month
- Storage: ~$10/month
- **Total: ~$105/month**

**To reduce costs:**
1. Use smaller node sizes during development
2. Scale down replicas when not in use
3. Use spot instances for non-critical workloads
4. Enable autoscaling to scale down during low traffic

## 📚 Next Steps

- [ ] Set up monitoring and alerts
- [ ] Configure backup strategy
- [ ] Implement blue-green deployment
- [ ] Add smoke tests to pipeline
- [ ] Set up staging environment
- [ ] Configure CDN for static assets
- [ ] Implement log aggregation
- [ ] Set up disaster recovery plan

## 🆘 Need Help?

- **Detailed docs**: See [CICD_README.md](CICD_README.md)
- **Azure issues**: Check [Azure Status](https://status.azure.com/)
- **Kubernetes help**: Run `kubectl explain <resource>`
- **GitHub Actions**: Check workflow logs

## 🎉 Success Indicators

Your deployment is successful when:

✅ All pods are in `Running` state
✅ Ingress shows external IP
✅ Health endpoints respond
✅ You can access the application
✅ Database migrations completed
✅ SSL certificate issued

```bash
# Quick health check
kubectl get pods -n ai-saas-dashboard
kubectl get ingress -n ai-saas-dashboard
curl https://your-domain.com/api/health
```

**Congratulations! Your app is live! 🚀**
