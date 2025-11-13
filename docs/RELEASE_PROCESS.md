# Release Process and Tagging Strategy

This document explains how to create releases and deploy to different environments using git tags and branch pushes.

## Overview

The CI/CD pipeline deployment strategy:

- **`dev` branch** → Deploys to **dev** environment on **every push** (no tag required)
- **`staging` branch** → Deploys to **staging** environment on **tag push only**
- **`main` branch** → Deploys to **main** environment on **tag push only**

### Image Tagging Strategy

- **Dev images**: Tagged with commit hash (e.g., `dev-a1b2c3d4`)
- **Staging/Main images**: Tagged with git tag (e.g., `v1.0.0-rc.1`, `v1.0.0`)
- **Latest tag**: Only applied to staging and main images, not dev

## Branch Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Git Branch Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  dev branch          staging branch        main branch     │
│  (Development)       (Pre-production)      (Production)    │
│       │                   │                     │          │
│  Push commit              │                     │          │
│  Auto-deploy ✓            │                     │          │
│  Image: dev-abc123        │                     │          │
│       │                   │                     │          │
│       │                   │ v1.0.0-rc.1         │          │
│       ├─────────────→     │ (tag required)      │          │
│       │                   │ Image: v1.0.0-rc.1  │          │
│       │                   │                     │ v1.0.0   │
│       │                   ├──────────────→      │ (tag req)│
│       │                   │                     │ Image:   │
│       │                   │                     │ v1.0.0   │
│       ▼                   ▼                     ▼          │
│    Deploy on           Deploy on            Deploy on     │
│   Every Push         Tag Push Only        Tag Push Only   │
│      DEV               STAGING                MAIN         │
└─────────────────────────────────────────────────────────────┘
```

## Tag Naming Convention

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

**Note**: Dev branch does not require tags. Images are automatically tagged with commit hashes.

## What Triggers Deployment?

| Branch | Trigger | Image Tag | Example |
|--------|---------|-----------|---------|
| **dev** | Every push to branch | `dev-<commit-hash>` | `dev-a1b2c3d4` |
| **staging** | Tag push only | `<git-tag>` + `latest` | `v1.0.0-rc.1` |
| **main** | Tag push only | `<git-tag>` + `latest` | `v1.0.0` |

### What Does NOT Trigger Deployment

❌ Pushing commits to `staging` branch without a tag
❌ Pushing commits to `main` branch without a tag
❌ Creating a tag on `dev` branch
❌ Creating branches
❌ Opening/merging pull requests

✅ **Deployment Only Happens When**:
- Push to `dev` branch (automatic, no tag needed)
- Push a `v*` tag to `staging` or `main` branch

## Release Workflow

### 1. Development Deployment (dev environment)

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

**Result**:
- Image built and tagged as `dev-<commit-hash>` (e.g., `dev-a1b2c3d4`)
- Automatically deployed to dev environment
- No "latest" tag applied

### 2. Staging Release (staging environment)

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

**Result**:
- Image built and tagged as `v1.0.0-rc.1` and `latest`
- Deployed to staging environment

### 3. Production Release (main environment)

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

**Result**:
- Image built and tagged as `v1.0.0` and `latest`
- Deployed to main (production) environment

## Automated Deployment Process

### Dev Branch (Push-based)

When you push to the `dev` branch, the CI/CD pipeline:

1. **Detects dev push** - Recognizes commit to dev branch
2. **Determines environment** - Sets environment to dev
3. **Builds images** - Tags images with commit hash (e.g., `dev-a1b2c3d4`)
4. **Scans for vulnerabilities** - Runs Trivy security scans
5. **Deploys to AKS** - Deploys to dev environment
6. **Verifies deployment** - Waits for rollout completion
7. **Sends notification** - Sends Slack notification (if configured)

### Staging/Main Branches (Tag-based)

When you push a tag to `staging` or `main` branch, the CI/CD pipeline:

1. **Checks the branch** - Validates the tag is on `staging` or `main`
2. **Determines environment** - Maps branch to environment (staging/main)
3. **Builds images** - Tags images with git tag (e.g., `v1.0.0`) plus `latest`
4. **Scans for vulnerabilities** - Runs Trivy security scans
5. **Deploys to AKS** - Deploys to the appropriate environment
6. **Verifies deployment** - Waits for rollout completion
7. **Sends notification** - Sends Slack notification (if configured)

### Deployment Flow Diagrams

**Dev Branch (Auto-deploy on push)**:
```
Push to dev branch
       │
       ▼
┌─────────────────┐
│  Detect Push    │ ◄── Recognizes dev branch commit
│  to Dev Branch  │
└────────┬────────┘
         │ ✅ Dev push detected
         ▼
┌─────────────────┐
│ Build & Push    │ ◄── Builds Docker images
│ Docker Images   │     Tags: dev-abc1234 (no latest)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Security Scan   │ ◄── Trivy vulnerability scan
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Deploy to AKS   │ ◄── Deploy to dev environment
│  Dev Env        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Verify & Notify │ ◄── Check rollout status
└─────────────────┘     Send Slack notification
```

**Staging/Main Branches (Tag-based)**:
```
Tag Push (v1.0.0)
       │
       ▼
┌─────────────────┐
│  Check Branch   │ ◄── Validates tag is on allowed branch
│  & Environment  │     (staging or main)
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
│  Environment    │     (staging or main)
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
   - **Environment**: dev, staging, or main
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
git push origin dev  # This auto-deploys to dev

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

### Dev deployment not triggering

**Check 1: Did you push to dev branch?**
```bash
git push origin dev
```

**Check 2: Check GitHub Actions**
Navigate to Actions tab and look for workflow runs triggered by push to dev

### Tag is not triggering deployment (staging/main)

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

The environment is determined by:
- Push to `dev` branch → dev environment (no tag needed)
- Tags on `staging` branch → staging environment
- Tags on `main` branch → main environment

If a tag exists on multiple branches, the pipeline uses this priority: main > staging

## Best Practices

1. **Always test in dev first** before promoting to staging/main
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
