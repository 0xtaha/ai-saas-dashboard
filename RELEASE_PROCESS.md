# Release Process and Tagging Strategy

This document explains how to create releases and deploy to different environments using git tags.

## Overview

The CI/CD pipeline is configured to deploy **only when a version tag is pushed** to one of the three main branches:

- `dev` → deploys to **dev** environment
- `staging` → deploys to **staging** environment
- `main` → deploys to **prod** environment

## Branch Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Git Branch Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  dev branch          staging branch        main branch     │
│  (Development)       (Pre-production)      (Production)    │
│       │                   │                     │          │
│       │ v1.0.0-dev.1      │                     │          │
│       ├─────────────→     │                     │          │
│       │                   │ v1.0.0-rc.1         │          │
│       │                   ├──────────────→      │          │
│       │                   │                     │ v1.0.0   │
│       │                   │                     ├──────→   │
│       │                   │                     │  Deploy  │
│       │                   │                     │   to     │
│       │                   │                     │  PROD    │
│       ▼                   ▼                     ▼          │
│    Deploy to           Deploy to            Deploy to     │
│      DEV               STAGING                PROD        │
└─────────────────────────────────────────────────────────────┘
```

## Tag Naming Convention

### Development Tags (dev branch)
```
v<major>.<minor>.<patch>-dev.<number>
```
Examples: `v1.0.0-dev.1`, `v1.2.0-dev.5`

### Staging Tags (staging branch)
```
v<major>.<minor>.<patch>-rc.<number>
```
Examples: `v1.0.0-rc.1`, `v1.2.0-rc.2`

### Production Tags (main branch)
```
v<major>.<minor>.<patch>
```
Examples: `v1.0.0`, `v1.2.0`, `v2.0.0`

## Release Workflow

### 1. Development Release (dev environment)

```bash
# Switch to dev branch
git checkout dev

# Make your changes and commit
git add .
git commit -m "feat: add new feature"

# Create a development tag
git tag v1.0.0-dev.1

# Push the tag (this triggers deployment to dev)
git push origin v1.0.0-dev.1

# Push the branch
git push origin dev
```

### 2. Staging Release (staging environment)

```bash
# Merge dev to staging
git checkout staging
git merge dev

# Create a release candidate tag
git tag v1.0.0-rc.1

# Push the tag (this triggers deployment to staging)
git push origin v1.0.0-rc.1

# Push the branch
git push origin staging
```

### 3. Production Release (prod environment)

```bash
# Merge staging to main
git checkout main
git merge staging

# Create a production tag
git tag v1.0.0

# Push the tag (this triggers deployment to prod)
git push origin v1.0.0

# Push the branch
git push origin main
```

## Automated Deployment Process

When you push a tag to one of the three main branches, the CI/CD pipeline:

1. **Checks the branch** - Validates the tag is on `dev`, `staging`, or `main`
2. **Determines environment** - Maps branch to environment (dev/staging/prod)
3. **Builds images** - Builds and pushes Docker images with the tag version
4. **Scans for vulnerabilities** - Runs Trivy security scans
5. **Deploys to AKS** - Deploys to the appropriate environment
6. **Verifies deployment** - Waits for rollout completion
7. **Sends notification** - Sends Slack notification (if configured)

### Deployment Flow Diagram

```
Tag Push (v1.0.0)
       │
       ▼
┌─────────────────┐
│  Check Branch   │ ◄── Validates tag is on allowed branch
│  & Environment  │     (dev, staging, main)
└────────┬────────┘
         │ ✅ Valid
         ▼
┌─────────────────┐
│ Build & Push    │ ◄── Builds Docker images
│ Docker Images   │     Tags: v1.0.0 and latest
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Security Scan   │ ◄── Trivy vulnerability scan
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Deploy to AKS   │ ◄── Deploy to appropriate environment
│  Environment    │     (dev/staging/prod)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Verify & Notify │ ◄── Check rollout status
└─────────────────┘     Send Slack notification
```

## Manual Deployment (Workflow Dispatch)

You can also manually trigger a deployment from GitHub Actions:

1. Go to **Actions** tab in GitHub
2. Select **CD - Deploy to Azure AKS**
3. Click **Run workflow**
4. Choose:
   - **Environment**: dev, staging, or prod
   - **Deployment Mode**: azure or onprem
5. Click **Run workflow**

## Viewing Deployments

### Check Active Tags
```bash
# List all tags
git tag -l

# Show tag details
git show v1.0.0

# Find which branch contains a tag
git branch -r --contains v1.0.0
```

### Check Deployment Status

#### GitHub Actions
Navigate to: `https://github.com/your-org/ai-saas-dashboard/actions`

#### Kubernetes Cluster
```bash
# Get current deployment version
kubectl get deployment backend -n app-backend -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check rollout status
kubectl rollout status deployment/backend -n app-backend

# View deployment history
kubectl rollout history deployment/backend -n app-backend
```

## Rollback Procedure

### Automatic Rollback
If deployment fails, the CI/CD pipeline automatically rolls back to the previous version.

### Manual Rollback

#### Via Kubernetes
```bash
# Rollback backend to previous version
kubectl rollout undo deployment/backend -n app-backend

# Rollback to specific revision
kubectl rollout undo deployment/backend -n app-backend --to-revision=2

# Check rollback status
kubectl rollout status deployment/backend -n app-backend
```

#### Via Git Tag Redeploy
```bash
# Find previous tag
git tag -l | sort -V | tail -n 5

# Create a new deployment with old tag
git checkout main
git tag v1.0.1  # New tag pointing to stable version
git push origin v1.0.1
```

## Hotfix Process

For urgent production fixes:

```bash
# Create hotfix branch from main
git checkout -b hotfix/critical-bug main

# Make the fix
git add .
git commit -m "fix: critical security issue"

# Merge to main
git checkout main
git merge hotfix/critical-bug

# Create hotfix tag
git tag v1.0.1

# Push tag (triggers deployment)
git push origin v1.0.1
git push origin main

# Backport to staging and dev
git checkout staging
git merge main
git push origin staging

git checkout dev
git merge staging
git push origin dev

# Delete hotfix branch
git branch -d hotfix/critical-bug
```

## Version Numbering

Follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backward-compatible new features
- **PATCH** version: Backward-compatible bug fixes

### Examples

```
v1.0.0      → Initial release
v1.0.1      → Patch: Bug fix
v1.1.0      → Minor: New feature (backward compatible)
v2.0.0      → Major: Breaking changes
```

## Required GitHub Secrets

Ensure the following secrets are configured in GitHub:

### Common Secrets
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
DEPLOYMENT_MODE (azure or onprem)
```

### Azure Mode Additional Secrets
```
AZURE_POSTGRES_HOST
AZURE_POSTGRES_PASSWORD
AZURE_REDIS_HOST
AZURE_REDIS_KEY
AZURE_STORAGE_CONNECTION_STRING
```

## Troubleshooting

### Tag is not triggering deployment

**Check 1: Is the tag on an allowed branch?**
```bash
git branch -r --contains v1.0.0
# Should show: origin/main, origin/staging, or origin/dev
```

**Check 2: Did you push the tag?**
```bash
git push origin v1.0.0
```

**Check 3: Check GitHub Actions**
Navigate to Actions tab and look for workflow runs

### Deployment failed

**Check workflow logs:**
1. Go to Actions tab
2. Click on the failed workflow run
3. Expand the failed job to see error details

**Common issues:**
- Missing secrets
- Insufficient Azure permissions
- Kubernetes cluster not accessible
- Docker image build failures

### Wrong environment deployed

The environment is determined by which branch the tag is on:
- Tags on `main` → prod
- Tags on `staging` → staging
- Tags on `dev` → dev

If a tag exists on multiple branches, the pipeline uses this priority: main > staging > dev

## Best Practices

1. **Always test in dev first** before promoting to staging/prod
2. **Use meaningful commit messages** following [Conventional Commits](https://www.conventionalcommits.org/)
3. **Tag after successful testing** in each environment
4. **Keep branches in sync** - regularly merge dev → staging → main
5. **Document breaking changes** in CHANGELOG.md
6. **Create GitHub Releases** with release notes for production tags
7. **Monitor deployments** - check logs and metrics after deployment
8. **Test rollback procedures** regularly in dev/staging

## Creating GitHub Releases

For production tags, create a GitHub Release:

1. Go to **Releases** → **Draft a new release**
2. Choose the tag (e.g., `v1.0.0`)
3. Release title: `Release v1.0.0`
4. Description:
   ```markdown
   ## What's New
   - Feature 1
   - Feature 2

   ## Bug Fixes
   - Fix 1
   - Fix 2

   ## Breaking Changes
   - Change 1
   ```
5. Click **Publish release**

## Support

For questions or issues with the release process:
- Check [DEPLOYMENT_MODES.md](DEPLOYMENT_MODES.md) for deployment configuration
- Review [CICD_README.md](CICD_README.md) for CI/CD pipeline details
- See [README.md](README.md) for general project documentation

---

**Last Updated:** 2025-01-12
