# AI SaaS Dashboard - Terraform Infrastructure

Infrastructure as Code (IaC) for deploying the AI SaaS Dashboard on Azure or on-premise Kubernetes.

## 📁 Directory Structure

```
terraform/
├── shared/              # Common configurations and variables
│   ├── variables.tf     # Shared variables across all deployments
│   └── outputs.tf       # Shared outputs
│
├── azure/               # Azure-specific deployment
│   ├── main.tf          # Azure provider and main configuration
│   ├── resource-group.tf
│   ├── aks.tf           # Azure Kubernetes Service
│   ├── acr.tf           # Azure Container Registry
│   ├── postgres.tf      # Azure Database for PostgreSQL
│   ├── redis.tf         # Azure Cache for Redis
│   ├── networking.tf    # VNet, subnets, NSG
│   ├── monitoring.tf    # Log Analytics, Application Insights
│   ├── storage.tf       # Azure Blob Storage
│   ├── variables.tf     # Azure-specific variables
│   └── outputs.tf       # Azure outputs
│
└── onprem/              # On-premise deployment
    ├── main.tf          # Kubernetes provider configuration
    ├── namespaces.tf    # Kubernetes namespaces
    ├── storage.tf       # StorageClass, PVCs
    ├── registry.tf      # Container registry (Harbor/Docker Registry)
    ├── database.tf      # PostgreSQL deployment
    ├── redis.tf         # Redis deployment
    ├── monitoring.tf    # Prometheus, Grafana, Loki
    ├── ingress.tf       # Ingress configuration
    ├── variables.tf     # On-premise specific variables
    └── outputs.tf       # On-premise outputs
```

---

## 🚀 Quick Start

### Azure Deployment

```bash
cd infra/terraform/azure

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Get outputs
terraform output
```

### On-Premise Deployment

```bash
cd infra/terraform/onprem

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_name = "ai-saas-dashboard"
environment  = "prod"
kubeconfig_path = "~/.kube/config"
storage_class = "longhorn"  # or local-path, nfs-client, etc.
app_domain = "ai-saas.yourdomain.com"
registry_domain = "registry.yourdomain.com"
EOF

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Get outputs
terraform output
```

---

## 📋 Prerequisites

### Azure Deployment

1. **Azure CLI** - [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform** - Version >= 1.5.0
   ```bash
   # macOS
   brew install terraform

   # Windows
   choco install terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
   unzip terraform_1.6.6_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl** - Kubernetes CLI
   ```bash
   az aks install-cli
   ```

### On-Premise Deployment

1. **Kubernetes Cluster** - Any distribution (K3s, RKE2, kubeadm, MicroK8s, etc.)
   ```bash
   # Example: Install K3s
   curl -sfL https://get.k3s.io | sh -

   # Get kubeconfig
   sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
   chmod 600 ~/.kube/config
   ```

2. **Terraform** - Version >= 1.5.0 (same as above)

3. **kubectl** - [Install Guide](https://kubernetes.io/docs/tasks/tools/)

4. **Storage Provisioner** - Choose one:
   - local-path (K3s built-in)
   - Longhorn: `kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml`
   - NFS: Configure NFS provisioner
   - Ceph/Rook: Install Rook operator

---

## 📚 Additional Resources

### Documentation
- [Azure Deployment Guide](../../docs/ARCHITECTURE_AZURE.md)
- [On-Premise Deployment Guide](../../docs/ONPREMISE_DEPLOYMENT.md)
- [Terraform Documentation](https://www.terraform.io/docs)

### Provider Documentation
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)

---

**Last Updated**: 2025-11-13
**Terraform Version**: >= 1.5.0
**Status**: Production Ready
