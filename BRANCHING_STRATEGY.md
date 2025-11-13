# Branching Strategy & CI/CD Workflow

This document outlines the branching strategy and CI/CD workflow for the AI SaaS Dashboard project.

## Branch Structure

```
main (production)
  ├── staging (pre-production)
  └── dev (development)
```

## CI/CD Flow Diagram

```mermaid
graph TB
    subgraph "Developer Actions"
        A[Developer pushes to dev] --> B{Trigger Type}
        C[Developer creates PR] --> D[CI Workflow]
        E[Developer pushes tag to staging/main] --> F{Tag Validation}
    end

    subgraph "CI Workflow - Continuous Integration"
        D --> G[Backend Tests]
        D --> H[Frontend Tests]
        D --> I[Security Scan]

        G --> J{All Tests Pass?}
        H --> J
        I --> J

        J -->|Yes| K[CI Success ✅]
        J -->|No| L[CI Failed ❌]
        L --> M[Block Merge/Deployment]
    end

    subgraph "CD Workflow - Dev Branch"
        B -->|Push to dev| N[Wait for CI]
        K --> N
        N --> O[Build Docker Images]
        O --> P["Tag: dev-hash"]
        P --> Q[Push to ACR]
        Q --> R[Security Scan Images]
        R --> S[Deploy to Dev Environment]
        S --> T{Deploy Success?}
        T -->|Yes| U[Dev Deployed ✅]
        T -->|No| V[Auto Rollback]
        V --> W[Notify Failure]
    end

    subgraph "CD Workflow - Staging/Main Branches"
        F -->|Valid Tag| X[Wait for CI]
        K --> X
        X --> Y[Determine Environment]
        Y --> Z{Which Branch?}

        Z -->|staging| AA[Build for Staging]
        Z -->|main| AB[Build for Production]

        AA --> AC[Tag: v1.0.0-rc.1 + latest]
        AB --> AD[Tag: v1.0.0 + latest]

        AC --> AE[Push to ACR]
        AD --> AE

        AE --> AF[Security Scan Images]
        AF --> AG[Create K8s Secrets]
        AG --> AH[Deploy Infrastructure]
        AH --> AI{Deployment Mode?}

        AI -->|onprem| AJ[Deploy PostgreSQL + Redis]
        AI -->|azure| AK[Use Azure Managed Services]

        AJ --> AL[Deploy Backend]
        AK --> AL

        AL --> AM[Deploy Frontend]
        AM --> AN[Deploy Monitoring]
        AN --> AO{Environment?}

        AO -->|main| AP[Deploy Ingress]
        AO -->|staging| AQ[Skip Ingress]

        AP --> AR[Run DB Migrations]
        AQ --> AR

        AR --> AS[Health Checks]
        AS --> AT{Deploy Success?}

        AT -->|Yes| AU[Deployed ✅]
        AT -->|No| AV[Auto Rollback]

        AV --> AW[Undo Backend]
        AW --> AX[Undo Frontend]
        AX --> AY[Notify Failure]
    end

    subgraph "Notifications"
        U --> AZ[Send Slack Notification]
        AU --> AZ
        W --> AZ
        AY --> AZ
    end

    style D fill:#4CAF50
    style K fill:#4CAF50
    style L fill:#f44336
    style U fill:#4CAF50
    style AU fill:#4CAF50
    style V fill:#FF9800
    style AV fill:#FF9800
    style M fill:#f44336
```

## Detailed CI/CD Flow by Branch

### Dev Branch Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant CI as CI Workflow
    participant CD as CD Workflow
    participant ACR as Azure Container Registry
    participant AKS as Azure AKS (Dev)

    Dev->>Git: Push to dev branch
    Git->>CI: Trigger CI Workflow

    par Backend Tests
        CI->>CI: Run Python linting (flake8)
        CI->>CI: Run pytest with coverage
    and Frontend Tests
        CI->>CI: Run ESLint
        CI->>CI: Run Jest tests
        CI->>CI: Build production bundle
    and Security
        CI->>CI: Run Trivy filesystem scan
    end

    alt CI Success
        CI->>CD: Trigger CD via workflow_run
        CD->>CD: Check CI status (must be success)
        CD->>CD: Build Docker images
        CD->>CD: Tag images (dev-a1b2c3d4)
        CD->>ACR: Push images to ACR
        CD->>CD: Scan Docker images (Trivy)
        CD->>AKS: Deploy to dev environment
        AKS->>CD: Deployment successful
        CD->>Dev: Notify success ✅
    else CI Failed
        CI->>Dev: Block deployment ❌
        CI->>Dev: Show test failures
    end
```

### Staging/Main Branch Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant CI as CI Workflow
    participant CD as CD Workflow
    participant ACR as Azure Container Registry
    participant AKS as Azure AKS
    participant Azure as Azure Services

    Dev->>Git: Push tag (v1.0.0 or v1.0.0-rc.1)
    Git->>CD: Trigger CD Workflow

    CD->>CD: Validate tag on correct branch
    CD->>CI: Wait for CI to complete

    alt CI Success
        CI->>CD: CI passed ✅
        CD->>CD: Determine environment (staging/main)
        CD->>CD: Build Docker images

        alt Staging
            CD->>CD: Tag images (v1.0.0-rc.1 + latest)
        else Main
            CD->>CD: Tag images (v1.0.0 + latest)
        end

        CD->>ACR: Push images to ACR
        CD->>CD: Scan Docker images (Trivy)
        CD->>AKS: Login to AKS cluster
        CD->>AKS: Create/Update K8s secrets

        alt Deployment Mode: onprem
            CD->>AKS: Deploy PostgreSQL
            CD->>AKS: Deploy Redis
        else Deployment Mode: azure
            CD->>Azure: Use managed PostgreSQL
            CD->>Azure: Use managed Redis
        end

        CD->>AKS: Deploy Backend (rolling update)
        CD->>AKS: Deploy Frontend (rolling update)
        CD->>AKS: Deploy Monitoring (Prometheus + Fluent Bit)

        alt Environment: main
            CD->>AKS: Deploy Ingress with SSL
        end

        CD->>AKS: Run database migrations
        CD->>AKS: Verify rollout status

        alt Deployment Success
            AKS->>CD: All pods healthy ✅
            CD->>Dev: Notify success
        else Deployment Failed
            AKS->>CD: Pods failing ❌
            CD->>AKS: Rollback backend
            CD->>AKS: Rollback frontend
            CD->>Dev: Notify failure + rollback
        end
    else CI Failed
        CI->>CD: CI failed ❌
        CD->>Dev: Abort deployment
    end
```

## Complete Workflow States

```mermaid
stateDiagram-v2
    [*] --> FeatureBranch: Create feature branch

    FeatureBranch --> PullRequest: Push & create PR
    PullRequest --> CI_Running: CI triggered

    CI_Running --> CI_Success: All tests pass
    CI_Running --> CI_Failed: Tests fail

    CI_Failed --> FeatureBranch: Fix issues
    CI_Success --> Merged_Dev: Merge to dev

    Merged_Dev --> Dev_CI: CI runs on push
    Dev_CI --> Dev_CD: CI passes
    Dev_CD --> Dev_Deployed: Auto-deploy

    Dev_Deployed --> Merged_Staging: Merge to staging
    Merged_Staging --> Staging_CI: CI runs
    Staging_CI --> Tag_Staging: Create RC tag
    Tag_Staging --> Staging_CD: CD triggered
    Staging_CD --> Staging_Deployed: Deploy staging

    Staging_Deployed --> Merged_Main: Merge to main
    Merged_Main --> Main_CI: CI runs on PR
    Main_CI --> Tag_Main: Create prod tag
    Tag_Main --> Main_CD: CD triggered
    Main_CD --> Production_Deployed: Deploy production

    Production_Deployed --> [*]

    Dev_CD --> Rollback_Dev: Deploy fails
    Staging_CD --> Rollback_Staging: Deploy fails
    Main_CD --> Rollback_Main: Deploy fails

    Rollback_Dev --> Dev_Deployed: Auto-rollback
    Rollback_Staging --> Staging_Deployed: Auto-rollback
    Rollback_Main --> Production_Deployed: Auto-rollback
```

### Branch Overview

| Branch | Purpose | Protection | Deployment Target |
|--------|---------|------------|-------------------|
| **main** | Production-ready code | Protected, requires PR + CI | Production (Azure AKS) |
| **staging** | Pre-production testing | Protected, requires PR + CI | Staging (Azure AKS) |
| **dev** | Active development | CI runs on push | Dev (Azure AKS) |

---

## CI/CD Pipeline

### 🧪 Continuous Integration (CI)

**Workflow**: `.github/workflows/ci.yml`

**Triggers**:
- Pull requests to: `main`, `staging`, `dev`
- Pushes to: `dev`, `staging`

**Jobs**:
1. **Backend Tests**
   - Linting with flake8
   - Unit tests with pytest
   - Coverage reporting
   - Services: PostgreSQL, Redis

2. **Frontend Tests**
   - ESLint checks
   - Jest unit tests
   - Production build validation
   - Coverage reporting

3. **Security Scan**
   - Trivy vulnerability scanning
   - SARIF upload to GitHub Security

**Requirements**: All CI jobs must pass before merging PRs

---

### 🚀 Continuous Deployment (CD)

**Workflow**: `.github/workflows/cd.yml`

**Triggers**:
- **Dev Environment**: Automatic on push to `dev` (after CI passes)
- **Staging Environment**: Manual tag push `v*` on `staging` branch
- **Main Environment**: Manual tag push `v*` on `main` branch
- **Manual Trigger**: Via workflow_dispatch for any environment

**Jobs**:

1. **Check CI Status**
   - Ensures CI passed before deployment
   - Validates branch and environment

2. **Build & Push Docker Images**
   - Backend image: `ai-saas-backend`
   - Frontend image: `ai-saas-frontend`
   - Tags:
     - Dev: `dev-{commit-hash}`
     - Staging/Main: Git tag (e.g., `v1.0.0`)
   - Push to Azure Container Registry
   - Vulnerability scanning with Trivy

3. **Deploy to Azure AKS**
   - Create Kubernetes namespaces
   - Deploy secrets and configmaps
   - Deploy backend (3 replicas, auto-scaling)
   - Deploy frontend (nginx)
   - Deploy monitoring stack (Prometheus, Fluent Bit)
   - Deploy ingress (main environment only)
   - Run database migrations (onprem mode only)

4. **Rollback** (on failure)
   - Automatic rollback to previous version

**Deployment Modes**:
- **Azure**: Uses managed Azure PostgreSQL, Redis, and Storage
- **On-Premise**: Deploys PostgreSQL and Redis in-cluster

---

## Workflow Examples

### 🔹 Development Workflow

```bash
# 1. Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/my-feature

# 2. Make changes and commit
git add .
git commit -m "feat: add new feature"

# 3. Push and create PR to dev
git push origin feature/my-feature
# Create PR on GitHub targeting 'dev' branch

# 4. CI runs automatically on PR
# - Backend tests
# - Frontend tests
# - Security scan

# 5. After PR approval and CI passes, merge to dev
# CD automatically deploys to dev environment
```

### 🔹 Staging Release Workflow

```bash
# 1. Merge dev into staging
git checkout staging
git pull origin staging
git merge dev

# 2. Push to staging (triggers CI)
git push origin staging

# 3. After CI passes, create release tag
git tag -a v1.0.0-rc.1 -m "Release candidate 1.0.0"
git push origin v1.0.0-rc.1

# 4. CD deploys to staging environment
```

### 🔹 Production Release Workflow

```bash
# 1. After staging testing, merge staging into main
git checkout main
git pull origin main
git merge staging

# 2. Create PR to main (requires reviews)
# CI runs on PR

# 3. After PR approval and merge, create production tag
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Production release 1.0.0"
git push origin v1.0.0

# 4. CD deploys to production (main) environment
```

### 🔹 Hotfix Workflow

```bash
# 1. Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-bug

# 2. Fix the issue and commit
git add .
git commit -m "fix: resolve critical bug"

# 3. Create PR to main
git push origin hotfix/critical-bug
# CI runs automatically

# 4. After approval, merge and tag
git checkout main
git merge hotfix/critical-bug
git tag -a v1.0.1 -m "Hotfix 1.0.1"
git push origin v1.0.1

# 5. Backport to staging and dev
git checkout staging
git merge hotfix/critical-bug
git push origin staging

git checkout dev
git merge hotfix/critical-bug
git push origin dev
```

---

## Tag Convention

Tags follow semantic versioning: `vMAJOR.MINOR.PATCH`

- **Production**: `v1.0.0`, `v1.0.1`, `v2.0.0`
- **Staging/RC**: `v1.0.0-rc.1`, `v1.0.0-rc.2`
- **Beta**: `v1.0.0-beta.1` (optional)

---

## Environment Configuration

### Dev Environment
- **Auto-deploy**: Yes (on every push)
- **Database**: In-cluster PostgreSQL or Azure managed
- **Redis**: In-cluster Redis or Azure managed
- **Monitoring**: Prometheus + Fluent Bit
- **Ingress**: Optional

### Staging Environment
- **Auto-deploy**: No (tag-based)
- **Database**: Azure managed PostgreSQL (recommended)
- **Redis**: Azure managed Redis (recommended)
- **Monitoring**: Full stack with alerts
- **Ingress**: Yes

### Main (Production) Environment
- **Auto-deploy**: No (tag-based)
- **Database**: Azure managed PostgreSQL
- **Redis**: Azure managed Redis
- **Monitoring**: Full stack with alerts + logging
- **Ingress**: Yes (with SSL/TLS)
- **Replicas**: 3-10 (auto-scaling)

---

## Required GitHub Secrets

### Azure Credentials
- `AZURE_CREDENTIALS` - Service principal credentials
- `AZURE_CONTAINER_REGISTRY` - ACR name
- `ACR_USERNAME` - ACR username
- `ACR_PASSWORD` - ACR password
- `AKS_CLUSTER_NAME` - AKS cluster name
- `AKS_RESOURCE_GROUP` - Azure resource group

### Application Secrets
- `SECRET_KEY` - Flask secret key
- `JWT_SECRET_KEY` - JWT signing key
- `POSTGRES_PASSWORD` - Database password
- `AI_API_KEY` - AI service API key
- `AI_API_URL` - AI service endpoint
- `REDIS_PASSWORD` - Redis password

### Azure Services (Azure mode)
- `AZURE_POSTGRES_HOST` - Managed PostgreSQL host
- `AZURE_POSTGRES_PASSWORD` - Managed PostgreSQL password
- `AZURE_REDIS_HOST` - Managed Redis host
- `AZURE_REDIS_KEY` - Managed Redis key
- `AZURE_STORAGE_CONNECTION_STRING` - Azure Storage connection

### Monitoring
- `AZURE_LOG_ANALYTICS_WORKSPACE_ID` - Log Analytics workspace ID
- `AZURE_LOG_ANALYTICS_WORKSPACE_KEY` - Log Analytics key
- `MONITORING_PASSWORD` - Basic auth password for monitoring UI

### Notifications (Optional)
- `SLACK_WEBHOOK` - Slack webhook URL for deployment notifications

---

## Best Practices

### ✅ Do's
- Always create feature branches from `dev`
- Write descriptive commit messages
- Keep branches up to date with parent branch
- Run tests locally before pushing
- Tag releases only after thorough testing
- Review deployment logs after CD runs

### ❌ Don'ts
- Don't commit directly to `main` or `staging`
- Don't skip CI checks
- Don't deploy to production without staging validation
- Don't use `--force` push on protected branches
- Don't commit secrets or credentials

---

## Monitoring & Rollback

### Monitoring Deployment
```bash
# Check deployment status
kubectl get pods -n app-backend
kubectl get pods -n app-frontend
kubectl get pods -n shared

# View logs
kubectl logs -f deployment/backend -n app-backend
kubectl logs -f deployment/frontend -n app-frontend

# Check rollout status
kubectl rollout status deployment/backend -n app-backend
```

### Manual Rollback
```bash
# Rollback backend
kubectl rollout undo deployment/backend -n app-backend

# Rollback frontend
kubectl rollout undo deployment/frontend -n app-frontend

# Rollback to specific revision
kubectl rollout undo deployment/backend -n app-backend --to-revision=2
```

---

## Troubleshooting

### CI Fails
1. Check workflow logs in GitHub Actions
2. Verify all tests pass locally
3. Check for linting errors
4. Ensure dependencies are up to date

### CD Fails
1. Verify Azure credentials are valid
2. Check Kubernetes cluster health
3. Ensure all required secrets are set
4. Review deployment logs
5. Check Docker images were pushed successfully

### Deployment Issues
1. Check pod status: `kubectl get pods -n <namespace>`
2. View pod logs: `kubectl logs <pod-name> -n <namespace>`
3. Check events: `kubectl get events -n <namespace>`
4. Verify secrets: `kubectl get secrets -n <namespace>`
5. Check ingress: `kubectl get ingress -A`

---

## Support

For questions or issues with the CI/CD pipeline:
1. Check GitHub Actions logs
2. Review this documentation
3. Contact the DevOps team
4. Create an issue in the repository

---

**Last Updated**: 2025-11-13
**Version**: 1.0.0
