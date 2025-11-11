#!/bin/bash

# Script to create Kubernetes secrets
# Usage: ./create-secrets.sh

set -e

NAMESPACE="ai-saas-dashboard"

echo "🔐 Creating Kubernetes Secrets for $NAMESPACE..."

# Check if namespace exists
kubectl get namespace $NAMESPACE &>/dev/null || kubectl create namespace $NAMESPACE

# Prompt for secrets
read -p "Enter SECRET_KEY: " SECRET_KEY
read -p "Enter JWT_SECRET_KEY: " JWT_SECRET_KEY
read -sp "Enter POSTGRES_PASSWORD: " POSTGRES_PASSWORD
echo ""
read -p "Enter AI_API_URL: " AI_API_URL
read -sp "Enter AI_API_KEY: " AI_API_KEY
echo ""

# Create secret
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY="$SECRET_KEY" \
  --from-literal=JWT_SECRET_KEY="$JWT_SECRET_KEY" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=AI_API_KEY="$AI_API_KEY" \
  --from-literal=AI_API_URL="$AI_API_URL" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created successfully!"
echo ""
echo "To view secrets (base64 encoded):"
echo "kubectl get secret app-secrets -n $NAMESPACE -o yaml"
