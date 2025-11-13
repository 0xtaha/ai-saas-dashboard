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
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "deployment_mode" {
  description = "Deployment mode: 'azure' for managed services, 'onprem' for in-cluster services"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "onprem"], var.deployment_mode)
    error_message = "Deployment mode must be either 'azure' or 'onprem'."
  }
}

# AKS Variables
variable "aks_node_count" {
  description = "Initial number of nodes in the AKS cluster"
  type        = number
  default     = 3
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "aks_max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

# PostgreSQL Variables (only used when deployment_mode = "azure")
variable "postgres_sku_name" {
  description = "SKU name for Azure PostgreSQL Flexible Server"
  type        = string
  default     = "GP_Standard_D4s_v3"
}

variable "postgres_storage_mb" {
  description = "Storage size in MB for PostgreSQL"
  type        = number
  default     = 131072 # 128 GB
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgres_admin_username" {
  description = "Admin username for PostgreSQL"
  type        = string
  default     = "dbadmin"
}

variable "postgres_backup_retention_days" {
  description = "Backup retention days for PostgreSQL"
  type        = number
  default     = 7
}

# Redis Variables (only used when deployment_mode = "azure")
variable "redis_sku" {
  description = "SKU for Azure Cache for Redis"
  type        = string
  default     = "Premium"
}

variable "redis_family" {
  description = "Family for Azure Cache for Redis"
  type        = string
  default     = "P"
}

variable "redis_capacity" {
  description = "Capacity for Azure Cache for Redis"
  type        = number
  default     = 1
}

# Container Registry Variables
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Premium"
}

# Log Analytics Variables
variable "log_analytics_retention_days" {
  description = "Retention days for Log Analytics workspace"
  type        = number
  default     = 30
}

# Networking Variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "postgres_subnet_address_prefix" {
  description = "Address prefix for PostgreSQL subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "redis_subnet_address_prefix" {
  description = "Address prefix for Redis subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AI SaaS Dashboard"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

# Storage Variables (only used when deployment_mode = "azure")
variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "GRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_replication_type)
    error_message = "Storage replication type must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for storage and other Azure services"
  type        = bool
  default     = false
}

variable "blob_lifecycle_days_to_cool" {
  description = "Days after which blobs are moved to cool tier"
  type        = number
  default     = 30
}

variable "blob_lifecycle_days_to_archive" {
  description = "Days after which blobs are moved to archive tier"
  type        = number
  default     = 90
}

variable "blob_lifecycle_days_to_delete" {
  description = "Days after which blobs are deleted"
  type        = number
  default     = 365
}
