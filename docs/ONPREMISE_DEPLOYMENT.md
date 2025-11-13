# Complete On-Premise Deployment Guide

This guide covers deploying the AI SaaS Dashboard entirely on-premise with **zero Azure dependencies**.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Component Selection](#component-selection)
- [Installation Steps](#installation-steps)
- [Configuration](#configuration)
- [Monitoring Setup](#monitoring-setup)
- [CI/CD Setup](#cicd-setup)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

---

## Overview

This deployment mode runs everything on your own infrastructure:
- ✅ No cloud provider dependencies
- ✅ Complete data sovereignty
- ✅ Full infrastructure control
- ✅ Cost-effective for existing hardware
- ✅ Air-gapped deployment capable

**What you need:**
- Kubernetes cluster (any distribution)
- Container registry (Harbor, Nexus, or built-in)
- Storage provisioner
- Ingress controller
- Optional: Load balancer

---

## Prerequisites

### Infrastructure Requirements

#### Minimum (Development/Testing)
- **Kubernetes**: 1 node with 8 CPU, 16GB RAM
- **Storage**: 100GB available
- **Network**: Private network access

#### Recommended (Small Production)
- **Kubernetes**: 3 nodes with 4 CPU, 8GB RAM each
- **Storage**: 500GB with replication
- **Network**: Private network + public ingress

#### Production (High Availability)
- **Kubernetes**: 5+ nodes with 8 CPU, 16GB RAM each
- **Storage**: 1TB+ with distributed storage (Ceph/Longhorn)
- **Network**: Load balancer, redundant network paths

### Kubernetes Distributions

Choose one of:

1. **kubeadm** - Bare metal Kubernetes
   ```bash
   # Good for: Custom hardware, full control
   # Complexity: High
   # Install: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
   ```

2. **K3s** - Lightweight Kubernetes
   ```bash
   # Good for: Edge, IoT, resource-constrained
   # Complexity: Low
   curl -sfL https://get.k3s.io | sh -
   ```

3. **RKE2** - Rancher Kubernetes Engine
   ```bash
   # Good for: Enterprise, security-focused
   # Complexity: Medium
   # Install: https://docs.rke2.io/install/quickstart
   ```

4. **MicroK8s** - Ubuntu's Kubernetes
   ```bash
   # Good for: Ubuntu environments, quick setup
   # Complexity: Low
   sudo snap install microk8s --classic
   ```

5. **Kind** - Kubernetes in Docker
   ```bash
   # Good for: Development only
   # Complexity: Very Low
   kind create cluster --name ai-saas
   ```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    On-Premise Infrastructure                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Node 1      │  │  Node 2      │  │  Node 3      │     │
│  │  (Control)   │  │  (Worker)    │  │  (Worker)    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                 │              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Kubernetes Cluster (K8s/K3s/RKE2)           │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │  Namespace: app-backend                     │    │  │
│  │  │  ├─ Backend (Flask) - 3 replicas            │    │  │
│  │  │  ├─ PostgreSQL - 1 replica + PVC            │    │  │
│  │  │  └─ Redis - 1 replica                       │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │  Namespace: app-frontend                    │    │  │
│  │  │  └─ Frontend (Nginx) - 2 replicas           │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │  Namespace: shared                          │    │  │
│  │  │  ├─ Prometheus - metrics                    │    │  │
│  │  │  ├─ Grafana - visualization                 │    │  │
│  │  │  ├─ Loki/Elasticsearch - logs               │    │  │
│  │  │  ├─ Fluent Bit - log collector              │    │  │
│  │  │  └─ Harbor/Registry - container images      │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │  Ingress Controller (nginx/traefik)         │    │  │
│  │  │  └─ SSL/TLS termination                     │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
│         │                                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Storage Layer                                       │  │
│  │  ├─ NFS / Longhorn / Ceph / Local-Path              │  │
│  │  └─ Persistent Volumes for databases & registry     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
   [External Access via LoadBalancer or NodePort]
```

---

## Component Selection

### 1. Storage Provisioner

| Solution | Best For | Complexity | Features |
|----------|----------|------------|----------|
| **local-path** | Dev, single-node | ⭐ | Simple, fast |
| **NFS** | Small prod, existing NFS | ⭐⭐ | Shared storage |
| **Longhorn** | Med prod, replication | ⭐⭐⭐ | Backup, snapshots |
| **Ceph/Rook** | Large prod, HA | ⭐⭐⭐⭐⭐ | Enterprise features |

**Recommendation**: Start with local-path or NFS, move to Longhorn for production.

### 2. Container Registry

| Solution | Best For | Complexity | Features |
|----------|----------|------------|----------|
| **Docker Registry** | Dev, simple needs | ⭐ | Basic, lightweight |
| **Harbor** | Production, security | ⭐⭐⭐ | Scanning, replication, RBAC |
| **Nexus OSS** | Multi-format repos | ⭐⭐⭐ | Maven, npm, Docker |
| **GitLab Registry** | If using GitLab | ⭐⭐ | Integrated CI/CD |

**Recommendation**: Harbor for production, Docker Registry for dev.

### 3. Logging Stack

| Solution | Best For | Complexity | Resource Usage |
|----------|----------|------------|----------------|
| **Loki + Grafana** | Small-med deployments | ⭐⭐ | Low (500MB) |
| **ELK Stack** | Large deployments, complex queries | ⭐⭐⭐⭐ | High (2GB+) |
| **File-based** | Development only | ⭐ | Minimal |

**Recommendation**: Loki for most use cases, ELK for large scale.

### 4. Ingress Controller

| Solution | Best For | Complexity | Features |
|----------|----------|------------|----------|
| **nginx** | General purpose | ⭐⭐ | Mature, well-documented |
| **Traefik** | Microservices, automatic config | ⭐⭐ | Auto-discovery, middleware |
| **HAProxy** | Performance-critical | ⭐⭐⭐ | High performance, TCP/HTTP |

**Recommendation**: nginx for simplicity, Traefik for automation.

---

## Installation Steps

### Step 1: Prepare Kubernetes Cluster

#### Option A: K3s (Recommended for most)

```bash
# Install K3s with embedded storage
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config

# Verify
kubectl get nodes
```

#### Option B: kubeadm (Full Kubernetes)

```bash
# Install container runtime (containerd)
sudo apt-get update
sudo apt-get install -y containerd

# Install kubeadm, kubelet, kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### Step 2: Install Storage Provisioner

#### Option A: Local-Path (Simplest)

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

# Set as default
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### Option B: Longhorn (Production)

```bash
# Install Longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml

# Wait for deployment
kubectl get pods -n longhorn-system --watch

# Access UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
# Visit: http://localhost:8080
```

#### Option C: NFS

```bash
# Install NFS provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=YOUR_NFS_SERVER_IP \
  --set nfs.path=/exported/path \
  --set storageClass.defaultClass=true
```

### Step 3: Install Ingress Controller

```bash
# Install nginx ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/baremetal/deploy.yaml

# Verify
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Step 4: Install Container Registry

#### Option A: Harbor (Recommended)

```bash
# Install Helm if not already installed
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Harbor Helm repository
helm repo add harbor https://helm.goharbor.io
helm repo update

# Install Harbor
helm install harbor harbor/harbor \
  --namespace shared \
  --create-namespace \
  --set expose.type=ingress \
  --set expose.ingress.hosts.core=harbor.yourdomain.com \
  --set externalURL=https://harbor.yourdomain.com \
  --set harborAdminPassword=Harbor12345 \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --set persistence.persistentVolumeClaim.database.size=5Gi

# Access Harbor
# Default credentials: admin / Harbor12345
```

#### Option B: Simple Docker Registry

```bash
# Apply the registry deployment
kubectl apply -f infra/k8s/onprem/container-registry.yaml

# Access via port-forward for initial setup
kubectl port-forward -n shared svc/docker-registry 5000:5000
```

### Step 5: Deploy Application

```bash
# Clone repository
git clone <your-repo-url>
cd ai-saas-dashboard

# Apply storage class configuration
kubectl apply -f infra/k8s/onprem/storage-class.yaml

# Create namespaces
kubectl apply -f infra/k8s/namespaces/namespaces.yaml

# Create secrets
kubectl create secret generic backend-secrets \
  --from-literal=SECRET_KEY=$(openssl rand -hex 32) \
  --from-literal=JWT_SECRET_KEY=$(openssl rand -hex 32) \
  --from-literal=POSTGRES_PASSWORD=$(openssl rand -hex 16) \
  --from-literal=REDIS_PASSWORD=$(openssl rand -hex 16) \
  --from-literal=AI_API_KEY=your-ai-api-key \
  --from-literal=AI_API_URL=your-ai-api-url \
  --namespace=app-backend

kubectl create secret generic monitoring-secrets \
  --from-literal=MONITORING_PASSWORD=$(openssl rand -hex 16) \
  --namespace=shared

# Deploy on-premise config
kubectl apply -f infra/k8s/overlays/onprem/backend-config.yaml

# Deploy PostgreSQL
kubectl apply -f infra/k8s/base/postgres-deployment.yaml

# Deploy Redis
kubectl apply -f infra/k8s/base/redis-deployment.yaml

# Wait for databases
kubectl wait --for=condition=ready pod -l app=postgres -n app-backend --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n app-backend --timeout=120s

# Build and push images (if using local registry)
export REGISTRY=localhost:5000  # or harbor.yourdomain.com
docker build -t $REGISTRY/ai-saas-backend:latest ./backend
docker build -t $REGISTRY/ai-saas-frontend:latest ./frontend
docker push $REGISTRY/ai-saas-backend:latest
docker push $REGISTRY/ai-saas-frontend:latest

# Update image references in deployments
export IMAGE_TAG=latest
export CONTAINER_REGISTRY=$REGISTRY
envsubst < infra/k8s/base/backend-deployment.yaml | kubectl apply -f -
envsubst < infra/k8s/base/frontend-deployment.yaml | kubectl apply -f -

# Deploy ingress
kubectl apply -f infra/k8s/base/ingress.yaml

# Verify deployment
kubectl get pods -n app-backend
kubectl get pods -n app-frontend
kubectl get svc -n app-backend
kubectl get svc -n app-frontend
kubectl get ingress -n app-frontend
```

### Step 6: Install Monitoring Stack

#### Option A: Loki + Grafana (Recommended)

```bash
# Deploy Loki
kubectl apply -f infra/k8s/onprem/loki.yaml

# Deploy Fluent Bit with Loki output
kubectl apply -f infra/k8s/onprem/fluent-bit-configmap.yaml
kubectl apply -f infra/k8s/monitoring/fluent-bit/rbac.yaml
kubectl apply -f infra/k8s/monitoring/fluent-bit/daemonset.yaml

# Deploy Prometheus
kubectl apply -f infra/k8s/monitoring/prometheus/

# Access Grafana
kubectl port-forward -n shared svc/grafana 3000:3000
# Visit: http://localhost:3000
# Default credentials: admin / (from monitoring-secrets)
```

#### Option B: ELK Stack

```bash
# Deploy Elasticsearch + Kibana
kubectl apply -f infra/k8s/onprem/elasticsearch.yaml

# Deploy Fluent Bit with Elasticsearch output
kubectl apply -f infra/k8s/onprem/fluent-bit-configmap.yaml
kubectl apply -f infra/k8s/monitoring/fluent-bit/rbac.yaml
kubectl apply -f infra/k8s/monitoring/fluent-bit/daemonset.yaml

# Access Kibana
kubectl port-forward -n shared svc/kibana 5601:5601
# Visit: http://localhost:5601
```

---

## Configuration

### DNS Setup

If using ingress with domain names:

```bash
# Get ingress external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Add to /etc/hosts or configure DNS
<EXTERNAL-IP> harbor.yourdomain.com
<EXTERNAL-IP> grafana.yourdomain.com
<EXTERNAL-IP> app.yourdomain.com
```

### SSL/TLS Certificates

#### Option A: cert-manager (Automatic Let's Encrypt)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

#### Option B: Self-Signed Certificates

```bash
# Generate self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=*.yourdomain.com/O=YourOrg"

# Create secret
kubectl create secret tls app-tls \
  --key=tls.key \
  --cert=tls.crt \
  --namespace=app-frontend
```

---

## CI/CD Setup

### Option 1: GitHub Actions with Self-Hosted Runner

```bash
# Install self-hosted runner
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux.tar.gz

# Configure
./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

Update GitHub Actions workflow to use self-hosted runner and on-premise registry. See [CI/CD updates section](#cicd-workflow-updates).

### Option 2: GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA ./backend
    - docker push $CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/backend backend=$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHA -n app-backend
  only:
    - main
```

### Option 3: Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t harbor.yourdomain.com/ai-saas/backend:${BUILD_NUMBER} ./backend'
                sh 'docker push harbor.yourdomain.com/ai-saas/backend:${BUILD_NUMBER}'
            }
        }
        stage('Deploy') {
            steps {
                sh 'kubectl set image deployment/backend backend=harbor.yourdomain.com/ai-saas/backend:${BUILD_NUMBER} -n app-backend'
            }
        }
    }
}
```

---

## Maintenance

### Backup Strategy

```bash
# Backup PostgreSQL
kubectl exec -n app-backend deployment/postgres -- pg_dumpall -U postgres > backup.sql

# Backup Kubernetes configs
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml

# Backup with Velero (recommended)
velero install --provider aws --bucket kubernetes-backups --backup-location-config region=minio
velero backup create ai-saas-backup --include-namespaces app-backend,app-frontend,shared
```

### Updates

```bash
# Update application
docker build -t $REGISTRY/ai-saas-backend:v1.1.0 ./backend
docker push $REGISTRY/ai-saas-backend:v1.1.0
kubectl set image deployment/backend backend=$REGISTRY/ai-saas-backend:v1.1.0 -n app-backend

# Update Kubernetes
# Follow your distribution's upgrade guide

# Update monitoring
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n shared
```

### Monitoring

```bash
# Check pod health
kubectl get pods --all-namespaces

# View logs
kubectl logs -f deployment/backend -n app-backend

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Access Grafana dashboards
kubectl port-forward -n shared svc/grafana 3000:3000
```

---

## Troubleshooting

### Pod Won't Start

```bash
# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous instance
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc --all-namespaces

# Check storage class
kubectl get storageclass

# Manually create PV if needed
kubectl apply -f manual-pv.yaml
```

### Network Issues

```bash
# Test pod networking
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod: wget http://backend-service.app-backend.svc.cluster.local:5000/api/health

# Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check ingress
kubectl get ingress --all-namespaces
kubectl describe ingress <name> -n <namespace>
```

### Registry Issues

```bash
# Test registry access
docker login harbor.yourdomain.com

# Check registry pod
kubectl logs -n shared deployment/docker-registry

# Verify image pull secret
kubectl get secret harbor-registry-secret -n app-backend -o yaml
```

---

## Cost Comparison

### On-Premise vs Cloud

| Component | On-Premise (3-year) | Azure (3-year) |
|-----------|---------------------|----------------|
| Servers (3x) | $9,000 | - |
| Storage (1TB) | $500 | - |
| Network | $1,000 | - |
| Power/Cooling | $1,500/year | - |
| Maintenance | $2,000/year | - |
| **Total** | **$19,000** | **$41,040** |

*Note: On-premise assumes existing infrastructure, datacenter space, and IT staff.*

---

## Next Steps

1. ✅ Set up monitoring alerts
2. ✅ Configure backup schedule
3. ✅ Implement disaster recovery plan
4. ✅ Set up development/staging environments
5. ✅ Configure SSL/TLS for all endpoints
6. ✅ Implement network policies
7. ✅ Set up log rotation
8. ✅ Document runbooks

---

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Harbor Documentation](https://goharbor.io/docs/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Last Updated**: 2025-11-13
**Version**: 1.0.0
