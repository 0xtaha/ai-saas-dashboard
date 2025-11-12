#!/bin/bash

# Script to create Kubernetes secrets for multi-namespace architecture
# Usage: ./create-secrets.sh [azure|onprem]

set -e

DEPLOYMENT_MODE="${1:-onprem}"

echo "🔐 Creating Kubernetes Secrets for multi-namespace deployment..."
echo "📦 Deployment mode: $DEPLOYMENT_MODE"

# Check if namespaces exist
kubectl get namespace app-backend &>/dev/null || kubectl create namespace app-backend
kubectl get namespace app-frontend &>/dev/null || kubectl create namespace app-frontend
kubectl get namespace shared &>/dev/null || kubectl create namespace shared

echo ""
echo "📝 Backend Secrets (app-backend namespace):"
# Prompt for backend secrets
read -p "Enter SECRET_KEY: " SECRET_KEY
read -p "Enter JWT_SECRET_KEY: " JWT_SECRET_KEY
read -sp "Enter POSTGRES_PASSWORD: " POSTGRES_PASSWORD
echo ""
read -p "Enter AI_API_URL: " AI_API_URL
read -sp "Enter AI_API_KEY: " AI_API_KEY
echo ""

# Create backend secret
kubectl create secret generic backend-secrets \
  --from-literal=SECRET_KEY="$SECRET_KEY" \
  --from-literal=JWT_SECRET_KEY="$JWT_SECRET_KEY" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=AI_API_KEY="$AI_API_KEY" \
  --from-literal=AI_API_URL="$AI_API_URL" \
  --namespace=app-backend \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Backend secrets created successfully!"

# Create Azure-specific secrets if in Azure mode
if [ "$DEPLOYMENT_MODE" == "azure" ]; then
  echo ""
  echo "📝 Azure Services Secrets (app-backend namespace):"
  echo "ℹ️  These can be obtained from Terraform outputs:"
  echo "    terraform output -json | jq -r '.postgres_host.value'"
  echo ""

  read -p "Enter AZURE_POSTGRES_HOST: " AZURE_POSTGRES_HOST
  read -sp "Enter AZURE_POSTGRES_PASSWORD: " AZURE_POSTGRES_PASSWORD
  echo ""
  read -p "Enter AZURE_REDIS_HOST: " AZURE_REDIS_HOST
  read -sp "Enter AZURE_REDIS_KEY: " AZURE_REDIS_KEY
  echo ""
  read -sp "Enter AZURE_STORAGE_CONNECTION_STRING: " AZURE_STORAGE_CONNECTION_STRING
  echo ""

  # Create Azure services secret
  kubectl create secret generic azure-services-secrets \
    --from-literal=AZURE_POSTGRES_HOST="$AZURE_POSTGRES_HOST" \
    --from-literal=AZURE_POSTGRES_PASSWORD="$AZURE_POSTGRES_PASSWORD" \
    --from-literal=AZURE_REDIS_HOST="$AZURE_REDIS_HOST" \
    --from-literal=AZURE_REDIS_KEY="$AZURE_REDIS_KEY" \
    --from-literal=AZURE_STORAGE_CONNECTION_STRING="$AZURE_STORAGE_CONNECTION_STRING" \
    --namespace=app-backend \
    --dry-run=client -o yaml | kubectl apply -f -

  echo "✅ Azure services secrets created successfully!"
fi

echo ""
echo "📝 Monitoring Secrets (shared namespace):"
# Prompt for monitoring secrets
read -p "Enter Azure Log Analytics WORKSPACE_ID: " WORKSPACE_ID
read -sp "Enter Azure Log Analytics WORKSPACE_KEY: " WORKSPACE_KEY
echo ""
read -sp "Enter Prometheus Basic Auth Password: " MONITORING_PASSWORD
echo ""

# Create monitoring secret for Fluent Bit
kubectl create secret generic monitoring-secrets \
  --from-literal=WORKSPACE_ID="$WORKSPACE_ID" \
  --from-literal=WORKSPACE_KEY="$WORKSPACE_KEY" \
  --namespace=shared \
  --dry-run=client -o yaml | kubectl apply -f -

# Create basic auth secret for Prometheus ingress
htpasswd -cb auth admin "$MONITORING_PASSWORD" 2>/dev/null || {
  echo "⚠️  htpasswd not found. Installing apache2-utils..."
  sudo apt-get update && sudo apt-get install -y apache2-utils
  htpasswd -cb auth admin "$MONITORING_PASSWORD"
}

kubectl create secret generic monitoring-basic-auth \
  --from-file=auth \
  --namespace=shared \
  --dry-run=client -o yaml | kubectl apply -f -

rm -f auth

echo "✅ Monitoring secrets created successfully!"

echo ""
echo "📋 Summary:"
echo "  - backend-secrets created in app-backend namespace"
if [ "$DEPLOYMENT_MODE" == "azure" ]; then
  echo "  - azure-services-secrets created in app-backend namespace"
fi
echo "  - monitoring-secrets created in shared namespace"
echo "  - monitoring-basic-auth created in shared namespace"
echo ""
echo "To view secrets (base64 encoded):"
echo "  kubectl get secret backend-secrets -n app-backend -o yaml"
if [ "$DEPLOYMENT_MODE" == "azure" ]; then
  echo "  kubectl get secret azure-services-secrets -n app-backend -o yaml"
fi
echo "  kubectl get secret monitoring-secrets -n shared -o yaml"
echo "  kubectl get secret monitoring-basic-auth -n shared -o yaml"
