# On-Premise Migration Summary

Complete guide for transitioning from Azure-dependent to pure on-premise deployment.

## 🎯 What's Been Changed

### 1. **Kubernetes Manifests** ✅

#### Storage Classes
- **File**: `infra/k8s/onprem/storage-class.yaml` (NEW)
- **Changes**:
  - Removed Azure-specific `managed-premium` storage class
  - Added 6 storage options: local-path, NFS, OpenEBS, Longhorn, Ceph/Rook, HostPath
  - Comprehensive guide for choosing the right storage

#### Database
- **File**: `infra/k8s/base/postgres-deployment.yaml`
- **Changes**:
  - Removed hardcoded `storageClassName: managed-premium`
  - Now uses default storage class or can be customized
  - Fully portable across any Kubernetes distribution

#### Container Registry
- **File**: `infra/k8s/onprem/container-registry.yaml` (NEW)
- **Options**:
  1. Harbor (production-ready with scanning)
  2. Docker Registry (simple, in-cluster)
  3. Nexus OSS (multi-format)
  4. GitLab Registry (if using GitLab)

### 2. **Monitoring Stack** ✅

#### Logging - Azure Log Analytics Removed
- **Files**:
  - `infra/k8s/onprem/fluent-bit-configmap.yaml` (NEW)
  - `infra/k8s/onprem/elasticsearch.yaml` (NEW)
  - `infra/k8s/onprem/loki.yaml` (NEW)

- **Options**:
  1. **Loki + Grafana** (lightweight, recommended)
  2. **ELK Stack** (Elasticsearch + Kibana)
  3. **Grafana Cloud Loki** (hybrid option)
  4. **File-based logging** (development)

- **Removed**:
  - Azure Log Analytics OUTPUT in Fluent Bit
  - `WORKSPACE_ID` and `WORKSPACE_KEY` dependencies

#### Visualization
- **Added**: Complete Grafana deployment with Prometheus and Loki datasources
- **Features**: Pre-configured dashboards, alerting, authentication

### 3. **Documentation** ✅

#### New Files Created
1. **`docs/ONPREMISE_DEPLOYMENT.md`** - Complete deployment guide
   - Architecture diagrams
   - Component selection matrix
   - Step-by-step installation
   - Configuration examples
   - Troubleshooting guide

2. **`infra/k8s/onprem/`** directory with:
   - `storage-class.yaml` - Storage provisioner options
   - `container-registry.yaml` - Registry deployments
   - `fluent-bit-configmap.yaml` - On-premise logging config
   - `elasticsearch.yaml` - ELK stack deployment
   - `loki.yaml` - PLG stack deployment

---

## 📦 New Components

### Storage Options

| Component | Use Case | Complexity | File |
|-----------|----------|------------|------|
| Local-Path | Development | ⭐ | storage-class.yaml |
| NFS | Small production | ⭐⭐ | storage-class.yaml |
| Longhorn | Medium production | ⭐⭐⭐ | storage-class.yaml |
| Ceph/Rook | Enterprise | ⭐⭐⭐⭐⭐ | storage-class.yaml |

### Container Registries

| Component | Use Case | Features | File |
|-----------|----------|----------|------|
| Harbor | Production | Scanning, RBAC, Replication | container-registry.yaml |
| Docker Registry | Development | Simple, lightweight | container-registry.yaml |
| Nexus OSS | Multi-format | Maven, npm, Docker | container-registry.yaml |

### Logging Solutions

| Component | Use Case | Resource Usage | Files |
|-----------|----------|----------------|-------|
| Loki | Small-Medium | Low (500MB) | loki.yaml + fluent-bit-configmap.yaml |
| Elasticsearch | Large | High (2GB+) | elasticsearch.yaml + fluent-bit-configmap.yaml |

---

## 🚀 Quick Start Guide

### For Small Teams (1-10 developers)

```bash
# 1. Install K3s
curl -sfL https://get.k3s.io | sh -

# 2. Apply storage (uses K3s built-in local-path)
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# 3. Deploy container registry
kubectl apply -f infra/k8s/onprem/container-registry.yaml

# 4. Deploy monitoring (Loki + Grafana)
kubectl apply -f infra/k8s/onprem/loki.yaml
kubectl apply -f infra/k8s/onprem/fluent-bit-configmap.yaml

# 5. Deploy application
kubectl apply -f infra/k8s/namespaces/
kubectl apply -f infra/k8s/overlays/onprem/
kubectl apply -f infra/k8s/base/postgres-deployment.yaml
kubectl apply -f infra/k8s/base/redis-deployment.yaml
kubectl apply -f infra/k8s/base/backend-deployment.yaml
kubectl apply -f infra/k8s/base/frontend-deployment.yaml
```

### For Medium Teams (10-50 developers)

```bash
# 1. Install RKE2 or full Kubernetes
# Follow: https://docs.rke2.io/install/quickstart

# 2. Install Longhorn storage
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml

# 3. Install Harbor registry
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor --namespace shared --create-namespace \
  --set expose.type=ingress \
  --set expose.ingress.hosts.core=harbor.yourdomain.com \
  --set harborAdminPassword=Harbor12345

# 4. Deploy monitoring (ELK Stack)
kubectl apply -f infra/k8s/onprem/elasticsearch.yaml
kubectl apply -f infra/k8s/onprem/fluent-bit-configmap.yaml

# 5. Deploy application
# Same as small teams, but configure HA for databases
```

---

## 🔄 Migration from Azure

### Phase 1: Preparation
1. ✅ Review new on-premise manifests
2. ✅ Choose storage provisioner
3. ✅ Choose container registry
4. ✅ Choose logging solution
5. ✅ Plan downtime window

### Phase 2: Infrastructure Setup
1. Install Kubernetes cluster
2. Install storage provisioner
3. Install ingress controller
4. Install container registry
5. Install monitoring stack

### Phase 3: Application Migration
1. Export data from Azure PostgreSQL
2. Build and push images to on-premise registry
3. Update image references in deployments
4. Import data to on-premise PostgreSQL
5. Update DNS/ingress configuration
6. Deploy application
7. Verify functionality

### Phase 4: Monitoring Migration
1. Stop Azure Log Analytics agents
2. Deploy on-premise logging (Loki/ELK)
3. Update Fluent Bit configuration
4. Deploy Grafana dashboards
5. Configure alerts

---

## ⚙️ Configuration Changes Needed

### 1. Update Image Registry

**Before (Azure)**:
```yaml
image: aisaasacr.azurecr.io/ai-saas-backend:latest
```

**After (On-Premise)**:
```yaml
image: harbor.yourdomain.com/ai-saas/backend:latest
# OR
image: registry.local:5000/ai-saas-backend:latest
```

### 2. Update Storage Classes

**Before (Azure)**:
```yaml
storageClassName: managed-premium
```

**After (On-Premise)**:
```yaml
storageClassName: longhorn  # or local-path, nfs-client, etc.
# OR omit to use default storage class
```

### 3. Update Monitoring

**Before (Azure Log Analytics)**:
```yaml
[OUTPUT]
    Name azure
    Match kube.*
    Customer_ID ${WORKSPACE_ID}
    Shared_Key ${WORKSPACE_KEY}
```

**After (Loki)**:
```yaml
[OUTPUT]
    Name loki
    Match kube.*
    Host loki.shared.svc.cluster.local
    Port 3100
```

**After (Elasticsearch)**:
```yaml
[OUTPUT]
    Name es
    Match kube.*
    Host elasticsearch.shared.svc.cluster.local
    Port 9200
```

---

## 🔐 Security Considerations

### 1. Container Registry Security
- Enable authentication (Harbor RBAC, Docker Registry basic auth)
- Use HTTPS/TLS for registry access
- Scan images for vulnerabilities (Harbor built-in scanner)

### 2. Network Security
- Implement Kubernetes Network Policies
- Use private networks for inter-pod communication
- Expose only necessary services via ingress

### 3. Data Security
- Enable encryption at rest for storage
- Use TLS for all external communications
- Rotate secrets regularly

### 4. Access Control
- Implement RBAC for Kubernetes
- Use service accounts with minimal permissions
- Enable audit logging

---

## 📊 Resource Requirements

### Minimum (Development)
- **CPU**: 8 cores
- **RAM**: 16GB
- **Storage**: 100GB
- **Nodes**: 1

### Recommended (Production)
- **CPU**: 12+ cores (across 3 nodes)
- **RAM**: 24GB+ (8GB per node)
- **Storage**: 500GB+ with replication
- **Nodes**: 3+

### Component Breakdown

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| Backend (3 replicas) | 750m | 3GB | - |
| Frontend (2 replicas) | 200m | 512MB | - |
| PostgreSQL | 500m | 512MB | 10GB |
| Redis | 200m | 256MB | - |
| Prometheus | 500m | 512MB | 10GB |
| Grafana | 200m | 512MB | 5GB |
| Loki | 500m | 512MB | 10GB |
| Elasticsearch (if used) | 1000m | 2GB | 30GB |
| Harbor (if used) | 500m | 1GB | 50GB |
| Ingress | 200m | 256MB | - |
| **Total** | **5-6 cores** | **9-12GB** | **115-145GB** |

---

## 🐛 Troubleshooting

### Storage Issues

**Problem**: PVC stays in Pending state
```bash
# Check storage class
kubectl get storageclass

# Check PVC
kubectl describe pvc <pvc-name> -n <namespace>

# Solution: Install storage provisioner or create manual PV
kubectl apply -f infra/k8s/onprem/storage-class.yaml
```

### Registry Issues

**Problem**: ImagePullBackOff errors
```bash
# Check image name
kubectl describe pod <pod-name> -n <namespace>

# Solution: Create image pull secret
kubectl create secret docker-registry registry-secret \
  --docker-server=harbor.yourdomain.com \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  --namespace=app-backend

# Add to service account
kubectl patch serviceaccount default -n app-backend \
  -p '{"imagePullSecrets":[{"name":"registry-secret"}]}'
```

### Logging Issues

**Problem**: No logs in Grafana/Kibana
```bash
# Check Fluent Bit
kubectl logs -n shared daemonset/fluent-bit

# Check Loki/Elasticsearch
kubectl logs -n shared deployment/loki
kubectl logs -n shared deployment/elasticsearch

# Verify configuration
kubectl get configmap fluent-bit-config -n shared -o yaml
```

---

## 📚 Additional Resources

### Documentation
- [Complete On-Premise Deployment Guide](docs/ONPREMISE_DEPLOYMENT.md)
- [Storage Class Options](infra/k8s/onprem/storage-class.yaml)
- [Container Registry Setup](infra/k8s/onprem/container-registry.yaml)
- [Logging Configuration](infra/k8s/onprem/fluent-bit-configmap.yaml)

### External Resources
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Harbor Documentation](https://goharbor.io/docs/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)

---

## ✅ Checklist

### Pre-Migration
- [ ] Review on-premise deployment guide
- [ ] Choose Kubernetes distribution
- [ ] Choose storage provisioner
- [ ] Choose container registry
- [ ] Choose logging solution
- [ ] Plan network architecture
- [ ] Estimate resource requirements
- [ ] Schedule downtime window

### Infrastructure Setup
- [ ] Install Kubernetes cluster
- [ ] Install storage provisioner
- [ ] Install ingress controller
- [ ] Install container registry
- [ ] Install monitoring stack (Prometheus, Grafana)
- [ ] Install logging stack (Loki or ELK)
- [ ] Configure SSL/TLS certificates

### Application Deployment
- [ ] Build Docker images
- [ ] Push images to on-premise registry
- [ ] Create Kubernetes secrets
- [ ] Deploy PostgreSQL
- [ ] Deploy Redis
- [ ] Deploy backend
- [ ] Deploy frontend
- [ ] Configure ingress
- [ ] Import data from Azure (if migrating)

### Post-Deployment
- [ ] Verify all pods are running
- [ ] Test application functionality
- [ ] Verify monitoring dashboards
- [ ] Test log collection
- [ ] Configure backup strategy
- [ ] Document configuration
- [ ] Update CI/CD pipelines
- [ ] Train team on new infrastructure

---

## 🎉 Benefits of On-Premise

✅ **Data Sovereignty**: Complete control over data location
✅ **Cost Savings**: No ongoing cloud costs (after initial investment)
✅ **Performance**: Lower latency for local users
✅ **Customization**: Full control over infrastructure
✅ **Security**: Data never leaves your premises
✅ **Compliance**: Easier regulatory compliance
✅ **Air-Gap Capable**: Can run completely isolated

---

**Last Updated**: 2025-11-13
**Version**: 1.0.0
**Status**: Ready for Production Use
