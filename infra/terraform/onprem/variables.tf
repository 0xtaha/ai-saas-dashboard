# On-Premise Specific Variables

# Inherit from shared module
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ai-saas-dashboard"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Logical location/datacenter name"
  type        = string
  default     = "on-premise"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AI SaaS Dashboard"
    ManagedBy   = "Terraform"
    Environment = "production"
    Deployment  = "on-premise"
  }
}

# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""  # Uses current context if empty
}

variable "create_namespaces" {
  description = "Whether to create namespaces (set to false if they already exist)"
  type        = bool
  default     = true
}

# Storage Configuration
variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "local-path"  # Default for K3s, change to longhorn, nfs-client, etc.
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "10Gi"
}

variable "registry_storage_size" {
  description = "Container registry storage size"
  type        = string
  default     = "50Gi"
}

variable "monitoring_storage_size" {
  description = "Monitoring stack storage size"
  type        = string
  default     = "30Gi"
}

# Container Registry Configuration
variable "registry_enabled" {
  description = "Deploy in-cluster container registry"
  type        = bool
  default     = true
}

variable "registry_type" {
  description = "Container registry type: docker-registry or harbor"
  type        = string
  default     = "docker-registry"
  validation {
    condition     = contains(["docker-registry", "harbor"], var.registry_type)
    error_message = "Registry type must be docker-registry or harbor."
  }
}

variable "registry_domain" {
  description = "Domain for container registry ingress"
  type        = string
  default     = "registry.local"
}

# Logging Configuration
variable "logging_backend" {
  description = "Logging backend: loki or elasticsearch"
  type        = string
  default     = "loki"
  validation {
    condition     = contains(["loki", "elasticsearch"], var.logging_backend)
    error_message = "Logging backend must be loki or elasticsearch."
  }
}

# Ingress Configuration
variable "ingress_class" {
  description = "Ingress class to use (nginx, traefik, etc.)"
  type        = string
  default     = "nginx"
}

variable "app_domain" {
  description = "Domain for application ingress"
  type        = string
  default     = "app.local"
}

variable "enable_tls" {
  description = "Enable TLS for ingresses"
  type        = bool
  default     = true
}

variable "cert_manager_enabled" {
  description = "Install and configure cert-manager for TLS"
  type        = bool
  default     = false
}

# Application Configuration
variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 3
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

# Database Configuration
variable "postgres_resources" {
  description = "PostgreSQL resource limits"
  type = object({
    requests_memory = string
    requests_cpu    = string
    limits_memory   = string
    limits_cpu      = string
  })
  default = {
    requests_memory = "256Mi"
    requests_cpu    = "250m"
    limits_memory   = "512Mi"
    limits_cpu      = "500m"
  }
}

# Monitoring Configuration
variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (leave empty to generate)"
  type        = string
  default     = ""
  sensitive   = true
}
