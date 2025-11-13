# CI/CD Pipeline - Azure Kubernetes Service Deployment

This document explains the complete CI/CD pipeline for deploying the AI SaaS Dashboard to Azure Kubernetes Service (AKS).

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [CI/CD Flow](#cicd-flow)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [GitHub Secrets Configuration](#github-secrets-configuration)
- [Workflow Details](#workflow-details)
- [Manual Deployment](#manual-deployment)
- [Monitoring and Rollback](#monitoring-and-rollback)
- [Troubleshooting](#troubleshooting)

## Overview

The CI/CD pipeline automates the entire process from code commit to production deployment on Azure AKS. It includes:

- ✅ Automated testing (Backend & Frontend)
- ✅ Code quality checks and linting
- ✅ Security vulnerability scanning
- ✅ Docker image building and pushing to Azure Container Registry (ACR)
- ✅ Automated deployment to AKS
- ✅ Database migrations
- ✅ Health checks and verification
- ✅ Automatic rollback on failure
- ✅ Slack notifications (optional)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────┐  │
│  │   Feature   │─▶│     Main    │─▶│   GitHub Actions       │  │
│  │   Branch    │  │   Branch    │  │   (CI/CD Workflows)    │  │
│  └─────────────┘  └─────────────┘  └────────────────────────┘  │
└─────────────────────────────────┬───────────────────────────────┘
                                  │
                                  ▼
         ┌────────────────────────────────────────────┐
         │    CI Pipeline (Pull Requests/Commits)     │
         │  ┌──────────────────────────────────────┐  │
         │  │  1. Backend Tests (Python/Pytest)    │  │
         │  │  2. Frontend Tests (React/Jest)      │  │
         │  │  3. Linting & Code Quality           │  │
         │  │  4. Security Scanning (Trivy)        │  │
         │  └──────────────────────────────────────┘  │
         └────────────────────────────────────────────┘
                                  │
                                  ▼
         ┌────────────────────────────────────────────┐
         │        CD Pipeline (Main Branch)           │
         │  ┌──────────────────────────────────────┐  │
         │  │  1. Build Docker Images              │  │
         │  │  2. Scan Images (Trivy)              │  │
         │  │  3. Push to Azure Container Registry │  │
         │  └──────────────────────────────────────┘  │
         └────────────────────────────────────────────┘
                                  │
                                  ▼
         ┌────────────────────────────────────────────┐
         │         Azure Kubernetes Service           │
         │  ┌──────────────────────────────────────┐  │
         │  │  1. Pull images from ACR             │  │
         │  │  2. Update deployments               │  │
         │  │  3. Rolling update (zero downtime)   │  │
         │  │  4. Run DB migrations                │  │
         │  │  5. Health checks                    │  │
         │  │  6. Auto-scaling                     │  │
         │  └──────────────────────────────────────┘  │
         │                                            │
         │  ┌─────────────┐  ┌─────────────┐         │
         │  │  Frontend   │  │   Backend   │         │
         │  │  (Nginx)    │  │   (Flask)   │         │
         │  │  Replicas:2 │  │  Replicas:3 │         │
         │  └─────────────┘  └─────────────┘         │
         │                                            │
         │  ┌─────────────┐  ┌─────────────┐         │
         │  │ PostgreSQL  │  │   Redis     │         │
         │  └─────────────┘  └─────────────┘         │
         └────────────────────────────────────────────┘
```

## CI/CD Flow

### 1. Continuous Integration (CI)

**Triggers:**
- Pull requests to `main` or `develop` branches
- Commits to `develop` branch

**Process:**
```
Pull Request Created/Updated
    │
    ├─▶ Backend Tests
    │   ├─ Python linting (flake8)
    │   ├─ Unit tests (pytest)
    │   └─ Coverage report
    │
    ├─▶ Frontend Tests
    │   ├─ ESLint
    │   ├─ Unit tests (Jest)
    │   └─ Build verification
    │
    └─▶ Security Scan
        └─ Trivy filesystem scan
```

**Workflow File:** `.github/workflows/ci.yml`

### 2. Continuous Deployment (CD)

**Deployment Strategy:**

The CD pipeline uses a **hybrid deployment strategy** based on the branch:

| Branch | Deployment Trigger | Image Tag Format | Latest Tag? |
|--------|-------------------|------------------|-------------|
| **dev** | Every push (no tag required) | `dev-<commit-hash>` | ❌ No |
| **staging** | Git tag push only | `<git-tag>` (e.g., `v1.0.0-rc.1`) | ✅ Yes |
| **main** | Git tag push only | `<git-tag>` (e.g., `v1.0.0`) | ✅ Yes |

**Key Points:**
- ✅ **Dev branch**: Auto-deploys on every push (simplified workflow)
- ✅ **Staging/Main branches**: Require explicit git tags for controlled releases
- ✅ **Unique dev images**: Each commit gets a unique image tag for easy tracking
- ✅ **Production safety**: Main deployments only happen via tags (prevents accidental releases)

**Triggers:**
- Push to `dev` branch (automatic deployment)
- Release tags on `staging` or `main` branches (`v*`)
- Manual workflow dispatch

**Process - Dev Branch (Auto-deploy):**
```
Push to dev branch
    │
    ├─▶ Build Phase
    │   ├─ Build backend Docker image
    │   ├─ Build frontend Docker image
    │   ├─ Tag images: dev-<8-char-commit-hash>
    │   └─ Scan images for vulnerabilities
    │
    ├─▶ Push Phase
    │   ├─ Login to Azure Container Registry
    │   ├─ Push backend image (without latest tag)
    │   └─ Push frontend image (without latest tag)
    │
    └─▶ Deploy Phase
        ├─ Login to Azure
        ├─ Get AKS credentials
        ├─ Update Kubernetes secrets
        ├─ Deploy to dev environment
        ├─ Health check verification
        └─ Send notification
```

**Process - Staging/Main Branches (Tag-based):**
```
Tag Push (v1.0.0 or v1.0.0-rc.1)
    │
    ├─▶ Validate Tag
    │   └─ Confirm tag is on allowed branch
    │
    ├─▶ Build Phase
    │   ├─ Build backend Docker image
    │   ├─ Build frontend Docker image
    │   ├─ Tag images: <git-tag> + latest
    │   └─ Scan images for vulnerabilities
    │
    ├─▶ Push Phase
    │   ├─ Login to Azure Container Registry
    │   ├─ Push backend image (with latest tag)
    │   └─ Push frontend image (with latest tag)
    │
    └─▶ Deploy Phase
        ├─ Login to Azure
        ├─ Get AKS credentials
        ├─ Determine environment (staging/main)
        ├─ Update Kubernetes secrets
        ├─ Apply ConfigMaps
        ├─ Deploy PostgreSQL (if onprem mode)
        ├─ Deploy Redis (if onprem mode)
        ├─ Deploy Backend (rolling update)
        ├─ Deploy Frontend (rolling update)
        ├─ Apply Ingress rules
        ├─ Run database migrations
        ├─ Health check verification
        └─ Send notification

Success ✅
    │
    └─▶ Production Ready

Failure ❌
    │
    └─▶ Automatic Rollback
        ├─ Undo Backend deployment
        ├─ Undo Frontend deployment
        └─ Notification sent
```

**Workflow File:** `.github/workflows/cd.yml`

### Image Tagging Examples

**Dev Environment:**
- Push commit `a1b2c3d4` to dev branch
- Image tags: `dev-a1b2c3d4`
- No `latest` tag applied

**Staging Environment:**
- Create tag `v1.0.0-rc.1` on staging branch
- Push tag: `git push origin v1.0.0-rc.1`
- Image tags: `v1.0.0-rc.1` and `latest`

**Main Environment:**
- Create tag `v1.0.0` on main branch
- Push tag: `git push origin v1.0.0`
- Image tags: `v1.0.0` and `latest`

## Prerequisites

Before setting up the CI/CD pipeline, ensure you have:

1. **Azure Account** with active subscription
2. **GitHub Repository** with admin access
3. **Azure CLI** installed locally
4. **kubectl** installed locally
5. **Helm** installed (for ingress setup)
6. **Domain name** (for production ingress)

## Initial Setup

### Step 1: Setup Azure Resources

Run the automated setup script:

```bash
# Set configuration (optional, defaults will be used)
export RESOURCE_GROUP="ai-saas-rg"
export LOCATION="eastus"
export AKS_CLUSTER_NAME="ai-saas-aks"
export ACR_NAME="aisaasacr"

# Run setup script
./scripts/deploy/setup-azure.sh
```

This script will:
- Create Azure Resource Group
- Create Azure Container Registry (ACR)
- Create AKS Cluster with autoscaling
- Install NGINX Ingress Controller
- Install cert-manager for SSL
- Configure Let's Encrypt

**Time:** ~15-20 minutes

### Step 2: Get Azure Service Principal

Create a service principal for GitHub Actions:

```bash
# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-ai-saas" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/ai-saas-rg \
  --sdk-auth
```

**Save the JSON output** - you'll need it for GitHub Secrets.

### Step 3: Configure DNS

Point your domain to the Ingress external IP:

```bash
# Get external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Create A record
# ai-saas.yourdomain.com → <EXTERNAL_IP>
```

### Step 4: Update Kubernetes Manifests

Edit `k8s/base/ingress.yaml`:

```yaml
spec:
  tls:
  - hosts:
    - ai-saas.yourdomain.com  # ← Change this
    secretName: ai-saas-tls
  rules:
  - host: ai-saas.yourdomain.com  # ← Change this
```

## GitHub Secrets Configuration

Go to your GitHub repository: **Settings → Secrets and variables → Actions**

Add the following secrets:

### Required Secrets

| Secret Name | Description | Example/Source |
|------------|-------------|----------------|
| `AZURE_CREDENTIALS` | Service principal JSON | Output from `az ad sp create-for-rbac` |
| `AZURE_CONTAINER_REGISTRY` | ACR name (without .azurecr.io) | `aisaasacr` |
| `ACR_USERNAME` | ACR admin username | From Azure Portal or CLI |
| `ACR_PASSWORD` | ACR admin password | From Azure Portal or CLI |
| `AKS_CLUSTER_NAME` | AKS cluster name | `ai-saas-aks` |
| `AKS_RESOURCE_GROUP` | Azure resource group | `ai-saas-rg` |
| `SECRET_KEY` | Flask secret key | Generate: `openssl rand -hex 32` |
| `JWT_SECRET_KEY` | JWT secret key | Generate: `openssl rand -hex 32` |
| `POSTGRES_PASSWORD` | Database password | Generate: `openssl rand -hex 16` |
| `AI_API_KEY` | AI service API key | From your AI provider |
| `AI_API_URL` | AI service API URL | `https://api.example.com` |

### Optional Secrets

| Secret Name | Description |
|------------|-------------|
| `SLACK_WEBHOOK` | Slack webhook for notifications |

**Important Note:** The production environment is now called "main" instead of "prod". If you have any manual workflow dispatch configurations, make sure to select "main" when deploying to production.

### Getting ACR Credentials

```bash
# Get ACR username
az acr credential show --name aisaasacr --query username -o tsv

# Get ACR password
az acr credential show --name aisaasacr --query passwords[0].value -o tsv
```

## Workflow Details

### CI Workflow (`.github/workflows/ci.yml`)

**Purpose:** Validate code quality and run tests

**Jobs:**

1. **backend-test**
   - Sets up Python 3.11
   - Installs dependencies
   - Runs flake8 linting
   - Executes pytest with coverage
   - Uploads coverage to Codecov

2. **frontend-test**
   - Sets up Node.js 18
   - Installs dependencies
   - Runs ESLint (optional)
   - Executes Jest tests with coverage
   - Builds production bundle
   - Uploads coverage to Codecov

3. **security-scan**
   - Runs Trivy security scanner
   - Scans for vulnerabilities in code
   - Uploads results to GitHub Security

**When it runs:**
- On every pull request
- On commits to `develop` branch

### CD Workflow (`.github/workflows/cd.yml`)

**Purpose:** Build, push, and deploy to AKS

**Jobs:**

1. **build-and-push**
   - Builds Docker images for backend and frontend
   - Tags with commit SHA or release tag
   - Pushes to Azure Container Registry
   - Scans images for vulnerabilities
   - Outputs image tag for deployment

2. **deploy-to-aks**
   - Logs into Azure
   - Gets AKS credentials
   - Determines deployment environment
   - Creates/updates Kubernetes secrets
   - Applies Kubernetes manifests
   - Performs rolling deployment
   - Runs database migrations
   - Verifies deployment health
   - Sends Slack notification

3. **rollback** (on failure)
   - Automatically triggered if deployment fails
   - Rolls back backend deployment
   - Rolls back frontend deployment
   - Verifies rollback status

**When it runs:**
- On push to `dev` branch (auto-deploy)
- On tag push to `staging` or `main` branches (v1.0.0-rc.1, v1.0.0, etc.)
- Manual trigger with environment selection

### Deployment Environments

| Environment | Branch | Trigger Type | Image Tag Format | Replicas | Autoscaling |
|------------|--------|--------------|------------------|----------|-------------|
| **Dev** | dev | Push to branch (auto) | `dev-<commit-hash>` | 1 | No |
| **Staging** | staging | Tag push only | `v*-rc.*` + latest | 2 | Yes (2-5) |
| **Main** | main | Tag push only | `v*` + latest | 3 | Yes (3-10) |

**Important Notes:**
- **Dev environment**: Deploys automatically on every push to the dev branch. No tags required.
- **Staging environment**: Deploys only when you push a tag like `v1.0.0-rc.1` to the staging branch.
- **Main environment**: Deploys only when you push a production tag like `v1.0.0` to the main branch (formerly called "prod").

## Deployment Workflows by Environment

### Development Workflow (dev branch)

**No tags required** - Just push to dev branch:

```bash
# Switch to dev branch
git checkout dev

# Make your changes and commit
git add .
git commit -m "feat: add new feature"

# Push the branch (this automatically triggers deployment)
git push origin dev
```

**Result:**
- Image built and tagged as `dev-<commit-hash>` (e.g., `dev-a1b2c3d4`)
- Automatically deployed to dev environment
- No "latest" tag applied

### Staging Workflow (staging branch)

**Tags required** - Create and push a tag:

```bash
# Merge dev to staging
git checkout staging
git merge dev

# Push the branch first
git push origin staging

# Create a release candidate tag
git tag v1.0.0-rc.1

# Push the tag (this triggers deployment to staging)
git push origin v1.0.0-rc.1
```

**Result:**
- Image built and tagged as `v1.0.0-rc.1` and `latest`
- Deployed to staging environment

### Production Workflow (main branch)

**Tags required** - Create and push a tag:

```bash
# Merge staging to main
git checkout main
git merge staging

# Push the branch first
git push origin main

# Create a production tag
git tag v1.0.0

# Push the tag (this triggers deployment to main)
git push origin v1.0.0
```

**Result:**
- Image built and tagged as `v1.0.0` and `latest`
- Deployed to main (production) environment

### What Does NOT Trigger Deployment

❌ Pushing commits to `staging` branch without a tag
❌ Pushing commits to `main` branch without a tag
❌ Creating a tag on `dev` branch
❌ Creating branches
❌ Opening/merging pull requests

✅ **Deployment Only Happens When**:
- Push to `dev` branch (automatic, no tag needed)
- Push a `v*` tag to `staging` or `main` branch

## Manual Deployment

For testing or emergency deployments:

### 1. Create Secrets

```bash
./scripts/deploy/create-secrets.sh
```

### 2. Deploy Manually

```bash
# Set variables
export ACR_NAME="aisaasacr"
export IMAGE_TAG="latest"

# Run deployment
./scripts/deploy/deploy-manual.sh
```

### 3. Verify Deployment

```bash
# Check pods
kubectl get pods -n ai-saas-dashboard

# Check services
kubectl get svc -n ai-saas-dashboard

# Check ingress
kubectl get ingress -n ai-saas-dashboard

# View logs
kubectl logs -f deployment/backend -n ai-saas-dashboard
kubectl logs -f deployment/frontend -n ai-saas-dashboard
```

## Monitoring and Rollback

### View Deployment Status

```bash
# Get all resources
kubectl get all -n ai-saas-dashboard

# Watch deployment progress
kubectl rollout status deployment/backend -n ai-saas-dashboard
kubectl rollout status deployment/frontend -n ai-saas-dashboard

# Get deployment history
kubectl rollout history deployment/backend -n ai-saas-dashboard
```

### Manual Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n ai-saas-dashboard
kubectl rollout undo deployment/frontend -n ai-saas-dashboard

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n ai-saas-dashboard
```

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n ai-saas-dashboard

# Frontend logs
kubectl logs -f deployment/frontend -n ai-saas-dashboard

# PostgreSQL logs
kubectl logs -f deployment/postgres -n ai-saas-dashboard

# All logs from a pod
kubectl logs <pod-name> -n ai-saas-dashboard --all-containers
```

### Port Forwarding (for debugging)

```bash
# Forward backend
kubectl port-forward service/backend-service 5000:5000 -n ai-saas-dashboard

# Forward frontend
kubectl port-forward service/frontend-service 3000:80 -n ai-saas-dashboard

# Forward database
kubectl port-forward service/postgres-service 5432:5432 -n ai-saas-dashboard
```

## Scaling

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment backend --replicas=5 -n ai-saas-dashboard

# Scale frontend
kubectl scale deployment frontend --replicas=3 -n ai-saas-dashboard
```

### Autoscaling Configuration

HPA (Horizontal Pod Autoscaler) is already configured:

**Backend:**
- Min: 3, Max: 10
- CPU: 70%, Memory: 80%

**Frontend:**
- Min: 2, Max: 5
- CPU: 70%

View autoscaling status:
```bash
kubectl get hpa -n ai-saas-dashboard
```

## Troubleshooting

### Deployment Issues

#### Dev deployment not triggering

**Check 1: Did you push to dev branch?**
```bash
git push origin dev
```

**Check 2: Check GitHub Actions**
Navigate to Actions tab and look for workflow runs triggered by push to dev

#### Tag is not triggering deployment (staging/main)

**Check 1: Is the tag on an allowed branch?**
```bash
git branch -r --contains v1.0.0
# Should show: origin/main or origin/staging (not origin/dev)
```

**Check 2: Did you push the tag?**
```bash
git push origin v1.0.0
```

**Check 3: Check GitHub Actions**
Navigate to Actions tab and look for workflow runs

#### Wrong environment deployed

The environment is determined by:
- Push to `dev` branch → dev environment (no tag needed)
- Tags on `staging` branch → staging environment
- Tags on `main` branch → main environment

If a tag exists on multiple branches, the pipeline uses this priority: main > staging

### Common Issues

#### 1. Pod CrashLoopBackOff

```bash
# View pod events
kubectl describe pod <pod-name> -n ai-saas-dashboard

# Check logs
kubectl logs <pod-name> -n ai-saas-dashboard --previous
```

**Common causes:**
- Database connection issues
- Missing environment variables
- Image pull errors

#### 2. ImagePullBackOff

```bash
# Check events
kubectl describe pod <pod-name> -n ai-saas-dashboard
```

**Solutions:**
- Verify ACR credentials
- Check if image exists
- Ensure AKS has permission to pull from ACR

#### 3. Service Unavailable

```bash
# Check service endpoints
kubectl get endpoints -n ai-saas-dashboard

# Check service
kubectl describe service <service-name> -n ai-saas-dashboard
```

#### 4. Database Connection Failed

```bash
# Check PostgreSQL pod
kubectl get pod -l app=postgres -n ai-saas-dashboard

# Check PostgreSQL logs
kubectl logs -f deployment/postgres -n ai-saas-dashboard

# Test connection from backend pod
kubectl exec -it <backend-pod> -n ai-saas-dashboard -- python -c "from app import create_app; app = create_app(); print('Connected!')"
```

#### 5. SSL Certificate Issues

```bash
# Check cert-manager
kubectl get certificate -n ai-saas-dashboard

# Check certificate status
kubectl describe certificate ai-saas-tls -n ai-saas-dashboard

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### Debug Commands

```bash
# Get all events
kubectl get events -n ai-saas-dashboard --sort-by='.lastTimestamp'

# Get resource usage
kubectl top pods -n ai-saas-dashboard
kubectl top nodes

# Execute commands in pod
kubectl exec -it <pod-name> -n ai-saas-dashboard -- /bin/bash

# Copy files from pod
kubectl cp <pod-name>:/path/to/file ./local-file -n ai-saas-dashboard
```

### GitHub Actions Debugging

Enable debug logging:

1. Go to repository **Settings → Secrets**
2. Add: `ACTIONS_STEP_DEBUG` = `true`
3. Re-run workflow

View workflow logs:
- Go to **Actions** tab
- Click on workflow run
- Expand job steps

## Deployment Best Practices

1. **Always test in dev first** before promoting to staging/main
2. **Use meaningful commit messages** following [Conventional Commits](https://www.conventionalcommits.org/)
3. **Tag after successful testing** in each environment
4. **Keep branches in sync** - regularly merge dev → staging → main
5. **Monitor deployments** - check logs and metrics after deployment
6. **Test rollback procedures** regularly in dev/staging

### Tag Naming Convention

**Staging Tags (staging branch):**
```
v<major>.<minor>.<patch>-rc.<number>
```
Examples: `v1.0.0-rc.1`, `v1.2.0-rc.2`

**Production Tags (main branch):**
```
v<major>.<minor>.<patch>
```
Examples: `v1.0.0`, `v1.2.0`, `v2.0.0`

**Note**: Dev branch does not require tags. Images are automatically tagged with commit hashes.

### Version Numbering

Follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backward-compatible new features
- **PATCH** version: Backward-compatible bug fixes

Examples:
```
v1.0.0      → Initial release
v1.0.1      → Patch: Bug fix
v1.1.0      → Minor: New feature (backward compatible)
v2.0.0      → Major: Breaking changes
```

## Security Best Practices

1. **Secrets Management**
   - Use GitHub Secrets for sensitive data
   - Consider Azure Key Vault integration
   - Rotate secrets regularly

2. **Image Scanning**
   - Automated Trivy scans in pipeline
   - Review scan results before deployment
   - Fix high/critical vulnerabilities

3. **Network Security**
   - Use Azure Network Policies
   - Restrict ingress to necessary ports
   - Enable SSL/TLS

4. **RBAC**
   - Implement Kubernetes RBAC
   - Principle of least privilege
   - Regular access reviews

## Cost Optimization

1. **Use Azure Reserved Instances** for predictable workloads
2. **Enable cluster autoscaling** to scale down during low traffic
3. **Use spot instances** for non-critical workloads
4. **Monitor resource usage** and right-size pods
5. **Set resource limits** on all containers

## Next Steps

- [ ] Set up monitoring (Azure Monitor, Prometheus)
- [ ] Configure alerts (Azure Alerts, PagerDuty)
- [ ] Implement backup strategy
- [ ] Set up disaster recovery
- [ ] Configure CDN for frontend assets
- [ ] Implement blue-green deployment
- [ ] Add smoke tests to deployment
- [ ] Set up log aggregation (ELK, Azure Log Analytics)

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Review Kubernetes events and pod logs
3. Consult [Troubleshooting](#troubleshooting) section
4. Create an issue on GitHub

## Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Helm Documentation](https://helm.sh/docs/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
