#!/bin/bash

# Manual Deployment Script for Multi-Namespace Architecture
# Use this for local testing or manual deployments

set -e

# Configuration
ACR_NAME="${ACR_NAME:-aisaasacr}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🚀 Starting multi-namespace deployment..."
echo "Image Tag: $IMAGE_TAG"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ kubectl is not configured. Please configure kubectl first."
    exit 1
fi

# Step 1: Create namespaces
echo "📦 Creating namespaces..."
kubectl apply -f infra/k8s/namespaces/namespaces.yaml

# Step 2: Check secrets
echo "🔐 Checking secrets..."
if ! kubectl get secret backend-secrets -n app-backend &>/dev/null; then
    echo "⚠️  Backend secrets not found. Please run ./scripts/deploy/create-secrets.sh first"
    exit 1
fi

if ! kubectl get secret monitoring-secrets -n shared &>/dev/null; then
    echo "⚠️  Monitoring secrets not found. Please run ./scripts/deploy/create-secrets.sh first"
    exit 1
fi

# Step 3: Deploy Backend Infrastructure
echo ""
echo "═══════════════════════════════════════════"
echo "  Backend Infrastructure (app-backend)"
echo "═══════════════════════════════════════════"

echo "🐘 Deploying PostgreSQL..."
kubectl apply -f infra/k8s/base/postgres-deployment.yaml

echo "📮 Deploying Redis..."
kubectl apply -f infra/k8s/base/redis-deployment.yaml

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n app-backend --timeout=300s

echo "⏳ Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n app-backend --timeout=120s

# Step 4: Deploy Backend Application
echo ""
echo "🔧 Deploying Backend Application..."
export AZURE_CONTAINER_REGISTRY="$ACR_NAME.azurecr.io"
export IMAGE_TAG="$IMAGE_TAG"
envsubst < infra/k8s/base/backend-deployment.yaml | kubectl apply -f -

echo "⏳ Waiting for backend deployment..."
kubectl rollout status deployment/backend -n app-backend --timeout=5m

# Step 5: Run database migrations
echo "🗄️  Running database migrations..."
BACKEND_POD=$(kubectl get pod -n app-backend -l app=backend -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n app-backend $BACKEND_POD -- python scripts/init_db.py || echo "⚠️  Migration failed or already initialized"

# Step 6: Deploy Frontend
echo ""
echo "═══════════════════════════════════════════"
echo "  Frontend Application (app-frontend)"
echo "═══════════════════════════════════════════"

echo "🎨 Deploying Frontend..."
envsubst < infra/k8s/base/frontend-deployment.yaml | kubectl apply -f -

echo "⏳ Waiting for frontend deployment..."
kubectl rollout status deployment/frontend -n app-frontend --timeout=5m

# Step 7: Deploy Monitoring Stack
echo ""
echo "═══════════════════════════════════════════"
echo "  Monitoring Stack (shared)"
echo "═══════════════════════════════════════════"

echo "📊 Deploying Fluent Bit (DaemonSet)..."
kubectl apply -f infra/k8s/monitoring/fluent-bit/

echo "📈 Deploying Prometheus..."
kubectl apply -f infra/k8s/monitoring/prometheus/

echo "⏳ Waiting for Prometheus deployment..."
kubectl rollout status deployment/prometheus -n shared --timeout=5m

# Step 8: Deploy Ingress
echo ""
echo "═══════════════════════════════════════════"
echo "  Ingress Configuration"
echo "═══════════════════════════════════════════"

echo "🌐 Deploying Ingress..."
kubectl apply -f infra/k8s/base/ingress.yaml

# Display deployment status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "═══════════════════════════════════════════"
echo "  Deployment Status"
echo "═══════════════════════════════════════════"

echo ""
echo "📦 app-backend namespace:"
kubectl get pods -n app-backend
echo ""
kubectl get services -n app-backend

echo ""
echo "📦 app-frontend namespace:"
kubectl get pods -n app-frontend
echo ""
kubectl get services -n app-frontend

echo ""
echo "📦 shared namespace (monitoring):"
kubectl get pods -n shared
echo ""
kubectl get services -n shared

echo ""
echo "🌐 Ingress:"
kubectl get ingress -n app-frontend
kubectl get ingress -n shared

# Get the external IPs
echo ""
echo "═══════════════════════════════════════════"
echo "  Access Information"
echo "═══════════════════════════════════════════"

APP_EXTERNAL_IP=$(kubectl get ingress -n app-frontend app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
MONITORING_EXTERNAL_IP=$(kubectl get ingress -n shared monitoring-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")

echo "Application External IP: $APP_EXTERNAL_IP"
echo "Monitoring External IP: $MONITORING_EXTERNAL_IP"
echo ""

echo "📋 Service FQDNs (for internal access):"
echo "  Backend:    http://backend-service.app-backend.svc.cluster.local:5000"
echo "  Frontend:   http://frontend-service.app-frontend.svc.cluster.local:80"
echo "  PostgreSQL: postgres-service.app-backend.svc.cluster.local:5432"
echo "  Redis:      redis-service.app-backend.svc.cluster.local:6379"
echo "  Prometheus: http://prometheus-service.shared.svc.cluster.local:9090"
echo ""

echo "📊 Monitoring Endpoints:"
echo "  Prometheus UI: kubectl port-forward -n shared svc/prometheus-service 9090:9090"
echo "  Then access:   http://localhost:9090"
echo ""

echo "📋 Useful Commands:"
echo "  Logs:"
echo "    kubectl logs -f deployment/backend -n app-backend"
echo "    kubectl logs -f deployment/frontend -n app-frontend"
echo "    kubectl logs -f deployment/prometheus -n shared"
echo "    kubectl logs -f daemonset/fluent-bit -n shared"
echo ""
echo "  Port-forward (for testing):"
echo "    kubectl port-forward service/backend-service 5000:5000 -n app-backend"
echo "    kubectl port-forward service/frontend-service 3000:80 -n app-frontend"
echo "    kubectl port-forward service/prometheus-service 9090:9090 -n shared"
echo ""
echo "  Resource usage:"
echo "    kubectl top pods -n app-backend"
echo "    kubectl top pods -n app-frontend"
echo "    kubectl top pods -n shared"
