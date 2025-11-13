# On-Premise Deployment - Main Configuration
# Deploys AI SaaS Dashboard on any Kubernetes cluster (K3s, RKE2, kubeadm, etc.)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "local" {
    # For on-premise, use local state or configure S3-compatible backend
    # path = "terraform.tfstate"
  }

  # Alternative: S3-compatible backend (MinIO, etc.)
  # backend "s3" {
  #   bucket                      = "terraform-state"
  #   key                         = "ai-saas-dashboard-onprem.tfstate"
  #   region                      = "us-east-1"
  #   endpoint                    = "https://minio.yourdomain.com"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   force_path_style            = true
  # }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}

# Load shared configuration
module "shared" {
  source = "../shared"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  tags         = var.tags
}
