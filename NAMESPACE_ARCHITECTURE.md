# Multi-Namespace Kubernetes Architecture

## Overview

The AI SaaS Dashboard is deployed across 3 namespaces with integrated monitoring:

```
├── app-backend (Namespace)
│   ├── Backend API (Flask)
│   ├── PostgreSQL Database  
│   └── Redis Cache
│
├── app-frontend (Namespace)
│   └── Frontend (React + Nginx)
│
└── shared (Namespace)
    ├── Fluent Bit (Log Aggregation)
    └── Prometheus (Metrics Collection)
```

## Namespace Structure

### 1. app-backend
**Purpose:** Backend application and data layer

**Components:**
- Backend Deployment (3-10 replicas)
- PostgreSQL StatefulSet (1 replica)
- Redis Deployment (1 replica)
- Persistent Volumes (uploaded files, database)

**Services:**
- `backend-service.app-backend.svc.cluster.local:5000`
- `postgres-service.app-backend.svc.cluster.local:5432`
- `redis-service.app-backend.svc.cluster.local:6379`

### 2. app-frontend
**Purpose:** Frontend application

**Components:**
- Frontend Deployment (2-5 replicas)

**Services:**
- `frontend-service.app-frontend.svc.cluster.local:80`

### 3. shared
**Purpose:** Monitoring and logging infrastructure

**Components:**
- Fluent Bit DaemonSet (runs on every node)
- Prometheus Deployment (metrics collection)
- ServiceMonitors (auto-discovery)

**Services:**
- `prometheus-service.shared.svc.cluster.local:9090`

## Communication Flow

```
Internet
    │
    ▼
Ingress Controller (nginx)
    │
    ├─► Frontend (app-frontend namespace)
    │       │
    │       └─► Backend API (app-backend namespace)
    │               │
    │               ├─► PostgreSQL (app-backend namespace)
    │               └─► Redis (app-backend namespace)
    │
    └─► Monitoring
            │
            ├─► Prometheus (shared namespace)
            │   ├─► Scrapes backend metrics
            │   └─► Scrapes frontend metrics
            │
            └─► Fluent Bit (shared namespace)
                ├─► Collects logs from app-backend
                ├─► Collects logs from app-frontend
                └─► Ships to Azure Log Analytics
```

## Cross-Namespace Service Discovery

Services use Fully Qualified Domain Names (FQDN):

```yaml
# Frontend → Backend
http://backend-service.app-backend.svc.cluster.local:5000

# Backend → PostgreSQL
postgresql://user:pass@postgres-service.app-backend.svc.cluster.local:5432/db

# Backend → Redis
redis://redis-service.app-backend.svc.cluster.local:6379

# Prometheus → Backend
http://backend-service.app-backend.svc.cluster.local:5000/metrics

# Prometheus → Frontend
http://frontend-service.app-frontend.svc.cluster.local:80/metrics
```

## Deployment Order

1. **Namespaces**
   ```bash
   kubectl apply -f k8s/namespaces/namespaces.yaml
   ```

2. **Secrets & ConfigMaps**
   ```bash
   kubectl apply -f k8s/base/backend-secrets.yaml
   kubectl apply -f k8s/base/backend-deployment.yaml  # Contains ConfigMap
   kubectl apply -f k8s/base/frontend-deployment.yaml # Contains ConfigMap
   ```

3. **Backend Infrastructure**
   ```bash
   kubectl apply -f k8s/base/postgres-deployment.yaml
   kubectl apply -f k8s/base/redis-deployment.yaml
   kubectl wait --for=condition=ready pod -l app=postgres -n app-backend --timeout=300s
   ```

4. **Applications**
   ```bash
   kubectl apply -f k8s/base/backend-deployment.yaml
   kubectl apply -f k8s/base/frontend-deployment.yaml
   ```

5. **Monitoring Stack**
   ```bash
   kubectl apply -f k8s/monitoring/fluent-bit/
   kubectl apply -f k8s/monitoring/prometheus/
   ```

6. **Ingress**
   ```bash
   kubectl apply -f k8s/base/ingress.yaml
   ```

## Monitoring Architecture

### Fluent Bit (Logging)
- **Deployment:** DaemonSet (one per node)
- **Purpose:** Collect logs from all pods
- **Output:** Azure Log Analytics Workspace
- **Configuration:**
  - Tail all container logs
  - Parse JSON logs
  - Add Kubernetes metadata
  - Filter by namespace

### Prometheus (Metrics)
- **Deployment:** StatefulSet with persistent storage
- **Purpose:** Scrape metrics from applications
- **Targets:**
  - Backend pods (port 5000, path /metrics)
  - Frontend pods (port 80, path /metrics)
  - PostgreSQL exporter
  - Redis exporter
- **Retention:** 15 days
- **Storage:** 50Gi persistent volume

## Security

### Network Policies
Each namespace has network policies allowing:
- Ingress from ingress-nginx
- Cross-namespace communication (backend ↔ frontend)
- Monitoring from shared namespace

### RBAC
- ServiceAccounts per namespace
- Role-based access control
- Fluent Bit needs cluster-wide read access
- Prometheus needs cluster-wide scrape access

## Resource Quotas

```yaml
app-backend:
  cpu: 10 cores
  memory: 20Gi
  persistentvolumeclaims: 10

app-frontend:
  cpu: 5 cores
  memory: 5Gi
  persistentvolumeclaims: 2

shared:
  cpu: 4 cores
  memory: 8Gi
  persistentvolumeclaims: 3
```

## Secrets Management

### app-backend namespace
```bash
kubectl create secret generic backend-secrets \
  --from-literal=SECRET_KEY="..." \
  --from-literal=JWT_SECRET_KEY="..." \
  --from-literal=POSTGRES_PASSWORD="..." \
  --from-literal=AI_API_KEY="..." \
  --from-literal=AI_API_URL="..." \
  -n app-backend
```

### shared namespace
```bash
kubectl create secret generic monitoring-secrets \
  --from-literal=WORKSPACE_ID="..." \
  --from-literal=WORKSPACE_KEY="..." \
  -n shared
```

## Monitoring Endpoints

- Prometheus UI: `kubectl port-forward -n shared svc/prometheus-service 9090:9090`
- Grafana (if deployed): `kubectl port-forward -n shared svc/grafana 3000:3000`
- Backend Metrics: `curl http://backend-service.app-backend.svc.cluster.local:5000/metrics`

## Useful Commands

```bash
# View all resources across namespaces
kubectl get all -n app-backend
kubectl get all -n app-frontend
kubectl get all -n shared

# Check logs
kubectl logs -f deployment/backend -n app-backend
kubectl logs -f deployment/frontend -n app-frontend
kubectl logs -f daemonset/fluent-bit -n shared

# Check metrics
kubectl top pods -n app-backend
kubectl top pods -n app-frontend

# Access Prometheus
kubectl port-forward -n shared svc/prometheus-service 9090:9090

# View Fluent Bit logs
kubectl logs -n shared -l app=fluent-bit --tail=100

# Scale deployments
kubectl scale deployment/backend --replicas=5 -n app-backend
kubectl scale deployment/frontend --replicas=3 -n app-frontend
```

## Migration from Single Namespace

If migrating from the old `ai-saas-dashboard` namespace:

```bash
# 1. Export existing data
kubectl get configmap app-config -n ai-saas-dashboard -o yaml > old-config.yaml
kubectl get secret app-secrets -n ai-saas-dashboard -o yaml > old-secrets.yaml

# 2. Create new namespaces
kubectl apply -f k8s/namespaces/namespaces.yaml

# 3. Migrate secrets to new namespaces
kubectl create secret generic backend-secrets \
  --from-literal=SECRET_KEY="..." \
  -n app-backend

# 4. Deploy to new namespaces
kubectl apply -f k8s/base/

# 5. Update ingress to point to new services
kubectl apply -f k8s/base/ingress.yaml

# 6. Delete old namespace (after verification)
kubectl delete namespace ai-saas-dashboard
```

## Benefits of Multi-Namespace Architecture

1. **Isolation:** Failures in one namespace don't affect others
2. **Security:** Granular RBAC and network policies
3. **Resource Management:** Separate quotas and limits
4. **Monitoring:** Dedicated monitoring namespace
5. **Scaling:** Independent scaling policies
6. **Development:** Easy to replicate structure for dev/staging
7. **Organization:** Clear separation of concerns
