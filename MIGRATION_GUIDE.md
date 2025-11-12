# Migration Guide - K8s Directory Move

## Overview

The `k8s/` directory has been moved under the `infra/` directory to better organize infrastructure-related code.

**Old Structure:**
```
ai-saas-dashboard/
├── k8s/
├── infra/
│   └── terraform/
```

**New Structure:**
```
ai-saas-dashboard/
├── infra/
│   ├── k8s/
│   └── terraform/
```

## What Changed

All Kubernetes manifests are now located under `infra/k8s/`:

- `k8s/namespaces/` → `infra/k8s/namespaces/`
- `k8s/base/` → `infra/k8s/base/`
- `k8s/overlays/` → `infra/k8s/overlays/`
- `k8s/monitoring/` → `infra/k8s/monitoring/`

## Updated Files

The following files have been automatically updated with the new paths:

### Scripts
- ✅ `scripts/deploy/deploy-manual.sh`
- ✅ `scripts/deploy/deploy-with-mode.sh`
- ✅ `scripts/deploy/create-secrets.sh`
- ✅ `scripts/deploy/setup-azure.sh`

### CI/CD
- ✅ `.github/workflows/cd.yml`
- ✅ `.github/workflows/ci.yml`

### Documentation
- ✅ `README.md`
- ✅ `DEPLOYMENT_MODES.md`
- ✅ `NAMESPACE_ARCHITECTURE.md`
- ✅ `CICD_README.md`
- ✅ `QUICK_START.md`

### New Documentation
- ✅ `infra/README.md` - Infrastructure overview
- ✅ `STRUCTURE.md` - Complete project structure

## Action Required

### If You Have Local Scripts

Update any local scripts or commands that reference the old paths:

**Before:**
```bash
kubectl apply -f k8s/base/backend-deployment.yaml
kubectl apply -f k8s/monitoring/prometheus/
cd k8s/overlays/azure
```

**After:**
```bash
kubectl apply -f infra/k8s/base/backend-deployment.yaml
kubectl apply -f infra/k8s/monitoring/prometheus/
cd infra/k8s/overlays/azure
```

### If You Have Existing Deployments

**No changes required!** The Kubernetes resources themselves are unchanged. Only the file locations in the repository have moved.

Your existing deployments will continue to work. When you need to update them, use the new paths:

```bash
# Update backend deployment
kubectl apply -f infra/k8s/base/backend-deployment.yaml

# Update monitoring stack
kubectl apply -f infra/k8s/monitoring/fluent-bit/
kubectl apply -f infra/k8s/monitoring/prometheus/
```

### If You Have Bookmarks or Documentation

Update any personal documentation or bookmarks to reference:
- `infra/k8s/` instead of `k8s/`

## Quick Migration Commands

### Clone Fresh Repository

```bash
git clone <repo-url>
cd ai-saas-dashboard

# All paths now use infra/k8s/
./scripts/deploy/deploy-with-mode.sh azure
```

### Update Existing Clone

```bash
cd ai-saas-dashboard
git pull origin main

# Verify new structure
ls -la infra/k8s/

# Deploy as usual
./scripts/deploy/deploy-with-mode.sh azure
```

### Verify Structure

```bash
# Check that k8s is under infra
cd ai-saas-dashboard
ls infra/

# Should show:
# k8s/
# terraform/
# README.md
```

## Common Tasks with New Paths

### Deploy Application

```bash
# Using deployment script (recommended)
./scripts/deploy/deploy-with-mode.sh azure

# Using kubectl directly
kubectl apply -f infra/k8s/namespaces/
kubectl apply -f infra/k8s/base/
kubectl apply -f infra/k8s/monitoring/

# Using kustomize
cd infra/k8s/overlays/azure
kustomize build . | kubectl apply -f -
```

### Update Deployments

```bash
# Edit manifest
nano infra/k8s/base/backend-deployment.yaml

# Apply changes
kubectl apply -f infra/k8s/base/backend-deployment.yaml
```

### View Manifests

```bash
# List all manifests
ls infra/k8s/base/
ls infra/k8s/monitoring/fluent-bit/
ls infra/k8s/monitoring/prometheus/

# View manifest
cat infra/k8s/base/backend-deployment.yaml
```

## Benefits of New Structure

1. **Better Organization** - All infrastructure code in one place
2. **Clear Separation** - Application vs infrastructure code
3. **Industry Standard** - Follows common project structure patterns
4. **Easier Navigation** - Related files grouped together
5. **Scalability** - Easy to add more infrastructure types (e.g., Helm charts)

## Troubleshooting

### "No such file or directory" Error

If you see errors like:
```
kubectl apply -f k8s/base/backend-deployment.yaml
Error: no such file or directory
```

**Solution:** Update your command to use the new path:
```bash
kubectl apply -f infra/k8s/base/backend-deployment.yaml
```

### CI/CD Pipeline Failing

If your CI/CD pipeline fails after pulling the latest changes:

1. **GitHub Actions** - Already updated, no action needed
2. **Custom pipelines** - Update paths in your pipeline configuration

### Kustomize Build Errors

If `kustomize build` fails:

**Old Command:**
```bash
cd k8s/overlays/azure
kustomize build .
```

**New Command:**
```bash
cd infra/k8s/overlays/azure
kustomize build .
```

## Questions?

See documentation:
- [Infrastructure README](infra/README.md)
- [Project Structure](STRUCTURE.md)
- [Quick Start Guide](QUICK_START.md)

---

**Migration Date:** 2025-01-12
**Breaking Changes:** None (only file locations changed)
