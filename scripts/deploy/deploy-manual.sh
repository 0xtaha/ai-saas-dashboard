#!/bin/bash

# Manual Deployment Script
# Use this for local testing or manual deployments

set -e

# Configuration
NAMESPACE="ai-saas-dashboard"
ACR_NAME="${ACR_NAME:-aisaasacr}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🚀 Starting manual deployment..."
echo "Namespace: $NAMESPACE"
echo "Image Tag: $IMAGE_TAG"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ kubectl is not configured. Please configure kubectl first."
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply configurations
echo "⚙️  Applying ConfigMaps..."
kubectl apply -f k8s/base/configmap.yaml

echo "🔐 Checking secrets..."
if ! kubectl get secret app-secrets -n $NAMESPACE &>/dev/null; then
    echo "⚠️  Secrets not found. Please run ./scripts/deploy/create-secrets.sh first"
    exit 1
fi

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
envsubst < k8s/base/postgres-deployment.yaml | kubectl apply -f -

# Deploy Redis
echo "📮 Deploying Redis..."
kubectl apply -f k8s/base/redis-deployment.yaml

# Wait for database to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s

# Deploy Backend
echo "🔧 Deploying Backend..."
export AZURE_CONTAINER_REGISTRY="$ACR_NAME.azurecr.io"
export IMAGE_TAG="$IMAGE_TAG"
envsubst < k8s/base/backend-deployment.yaml | kubectl apply -f -

# Deploy Frontend
echo "🎨 Deploying Frontend..."
envsubst < k8s/base/frontend-deployment.yaml | kubectl apply -f -

# Deploy Ingress
echo "🌐 Deploying Ingress..."
envsubst < k8s/base/ingress.yaml | kubectl apply -f -

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment/backend -n $NAMESPACE --timeout=5m
kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=5m

# Run database migrations
echo "🗄️  Running database migrations..."
BACKEND_POD=$(kubectl get pod -n $NAMESPACE -l app=backend -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n $NAMESPACE $BACKEND_POD -- python scripts/init_db.py || echo "⚠️  Migration failed or already initialized"

# Display deployment status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Deployment Status:"
echo "─────────────────────────────────────────"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get ingress -n $NAMESPACE
echo ""

# Get the external IP
EXTERNAL_IP=$(kubectl get ingress -n $NAMESPACE ai-saas-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")

echo "🌍 Access Information:"
echo "External IP: $EXTERNAL_IP"
echo ""
echo "To get logs:"
echo "  Backend:  kubectl logs -f deployment/backend -n $NAMESPACE"
echo "  Frontend: kubectl logs -f deployment/frontend -n $NAMESPACE"
echo ""
echo "To port-forward (for testing):"
echo "  Backend:  kubectl port-forward service/backend-service 5000:5000 -n $NAMESPACE"
echo "  Frontend: kubectl port-forward service/frontend-service 3000:80 -n $NAMESPACE"
