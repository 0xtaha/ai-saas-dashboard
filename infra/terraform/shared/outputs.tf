output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_kube_config" {
  description = "Kubernetes config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin username for ACR"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for ACR"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_workspace_key" {
  description = "Primary shared key for Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# PostgreSQL outputs (Azure mode only)
output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = var.deployment_mode == "azure" ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}

output "postgres_admin_username" {
  description = "Admin username for PostgreSQL"
  value       = var.deployment_mode == "azure" ? var.postgres_admin_username : null
}

output "postgres_admin_password" {
  description = "Admin password for PostgreSQL"
  value       = var.deployment_mode == "azure" ? random_password.postgres[0].result : null
  sensitive   = true
}

output "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  value       = var.deployment_mode == "azure" ? azurerm_postgresql_flexible_server_database.main[0].name : null
}

# Redis outputs (Azure mode only)
output "redis_hostname" {
  description = "Hostname of the Azure Redis Cache"
  value       = var.deployment_mode == "azure" ? azurerm_redis_cache.main[0].hostname : null
}

output "redis_ssl_port" {
  description = "SSL port of the Azure Redis Cache"
  value       = var.deployment_mode == "azure" ? azurerm_redis_cache.main[0].ssl_port : null
}

output "redis_primary_access_key" {
  description = "Primary access key for Azure Redis Cache"
  value       = var.deployment_mode == "azure" ? azurerm_redis_cache.main[0].primary_access_key : null
  sensitive   = true
}

output "redis_connection_string" {
  description = "Connection string for Azure Redis Cache"
  value       = var.deployment_mode == "azure" ? "${azurerm_redis_cache.main[0].hostname}:${azurerm_redis_cache.main[0].ssl_port},password=${azurerm_redis_cache.main[0].primary_access_key},ssl=True,abortConnect=False" : null
  sensitive   = true
}

# Deployment mode
output "deployment_mode" {
  description = "Deployment mode (azure or onprem)"
  value       = var.deployment_mode
}

# Kubernetes namespaces
output "kubernetes_namespaces" {
  description = "Created Kubernetes namespaces"
  value = {
    backend    = kubernetes_namespace.app_backend.metadata[0].name
    frontend   = kubernetes_namespace.app_frontend.metadata[0].name
    monitoring = kubernetes_namespace.shared.metadata[0].name
  }
}

# Instructions
output "next_steps" {
  description = "Next steps for deployment"
  value = var.deployment_mode == "azure" ? <<-EOT
    Azure Managed Services Mode:

    1. Get AKS credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name}

    2. Verify connection:
       kubectl get nodes

    3. Deploy application:
       cd scripts/deploy
       ./deploy-with-mode.sh azure

    4. Access services:
       - PostgreSQL: ${azurerm_postgresql_flexible_server.main[0].fqdn}
       - Redis: ${azurerm_redis_cache.main[0].hostname}
       - ACR: ${azurerm_container_registry.acr.login_server}
  EOT
  : <<-EOT
    On-Premise Mode:

    1. Get AKS credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name}

    2. Verify connection:
       kubectl get nodes

    3. Deploy application:
       cd scripts/deploy
       ./deploy-with-mode.sh onprem

    4. PostgreSQL and Redis will be deployed in-cluster
  EOT
}

# Storage outputs (Azure mode only)
output "storage_account_name" {
  description = "Name of the storage account"
  value       = var.deployment_mode == "azure" ? azurerm_storage_account.main[0].name : null
}

output "storage_account_primary_access_key" {
  description = "Primary access key for storage account"
  value       = var.deployment_mode == "azure" ? azurerm_storage_account.main[0].primary_access_key : null
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Connection string for storage account"
  value       = var.deployment_mode == "azure" ? azurerm_storage_account.main[0].primary_connection_string : null
  sensitive   = true
}

output "storage_blob_endpoint" {
  description = "Blob endpoint for storage account"
  value       = var.deployment_mode == "azure" ? azurerm_storage_account.main[0].primary_blob_endpoint : null
}

output "uploaded_files_container_name" {
  description = "Name of the uploaded files container"
  value       = var.deployment_mode == "azure" ? azurerm_storage_container.uploaded_files[0].name : null
}
