#!/bin/bash

# Azure AKS Setup Script
# This script sets up Azure resources for the AI SaaS Dashboard

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-ai-saas-rg}"
LOCATION="${LOCATION:-eastus}"
AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME:-ai-saas-aks}"
ACR_NAME="${ACR_NAME:-aisaasacr}"
NODE_COUNT="${NODE_COUNT:-3}"
NODE_VM_SIZE="${NODE_VM_SIZE:-Standard_D2s_v3}"

echo "🚀 Setting up Azure Resources..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "ACR Name: $ACR_NAME"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Login to Azure
echo "🔐 Logging in to Azure..."
az login

# Create Resource Group
echo "📦 Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Create Azure Container Registry
echo "🐳 Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Standard \
    --location $LOCATION

# Enable admin user for ACR (needed for AKS integration)
echo "🔑 Enabling ACR admin user..."
az acr update \
    --name $ACR_NAME \
    --admin-enabled true

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

echo "📝 ACR Credentials:"
echo "Username: $ACR_USERNAME"
echo "Password: $ACR_PASSWORD"
echo ""

# Create AKS Cluster
echo "☸️  Creating AKS Cluster (this may take 10-15 minutes)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $NODE_VM_SIZE \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME \
    --enable-managed-identity \
    --network-plugin azure \
    --enable-cluster-autoscaler \
    --min-count 2 \
    --max-count 10

# Get AKS credentials
echo "🔧 Configuring kubectl..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --overwrite-existing

# Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
kubectl create namespace ingress-nginx || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux

# Install cert-manager for SSL
echo "🔒 Installing cert-manager..."
kubectl create namespace cert-manager || true
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
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

# Get the external IP of the ingress controller
echo "⏳ Waiting for Ingress Controller to get external IP..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s

EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo ""
echo "✅ Azure Setup Complete!"
echo ""
echo "📋 Summary:"
echo "─────────────────────────────────────────"
echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "ACR Name: $ACR_NAME.azurecr.io"
echo "Ingress External IP: $EXTERNAL_IP"
echo ""
echo "🔑 ACR Credentials (save these for GitHub Secrets):"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
echo ""
echo "📝 Next Steps:"
echo "1. Configure DNS to point to: $EXTERNAL_IP"
echo "2. Update infra/k8s/base/ingress.yaml with your domain"
echo "3. Add GitHub Secrets:"
echo "   - AZURE_CREDENTIALS"
echo "   - AZURE_CONTAINER_REGISTRY: $ACR_NAME"
echo "   - ACR_USERNAME: $ACR_USERNAME"
echo "   - ACR_PASSWORD: $ACR_PASSWORD"
echo "   - AKS_CLUSTER_NAME: $AKS_CLUSTER_NAME"
echo "   - AKS_RESOURCE_GROUP: $RESOURCE_GROUP"
echo ""
