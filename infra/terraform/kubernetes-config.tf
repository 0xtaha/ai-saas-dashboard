# Kubernetes Namespaces
resource "kubernetes_namespace" "app_backend" {
  metadata {
    name = "app-backend"
    labels = {
      name        = "app-backend"
      environment = var.environment
      monitoring  = "enabled"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_namespace" "app_frontend" {
  metadata {
    name = "app-frontend"
    labels = {
      name        = "app-frontend"
      environment = var.environment
      monitoring  = "enabled"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_namespace" "shared" {
  metadata {
    name = "shared"
    labels = {
      purpose     = "monitoring"
      environment = var.environment
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Kubernetes Secret for Azure Services (Azure mode only)
resource "kubernetes_secret" "azure_services" {
  count = var.deployment_mode == "azure" ? 1 : 0

  metadata {
    name      = "azure-services-secrets"
    namespace = kubernetes_namespace.app_backend.metadata[0].name
  }

  data = {
    AZURE_POSTGRES_HOST             = azurerm_postgresql_flexible_server.main[0].fqdn
    AZURE_POSTGRES_PASSWORD         = random_password.postgres[0].result
    AZURE_REDIS_HOST                = azurerm_redis_cache.main[0].hostname
    AZURE_REDIS_KEY                 = azurerm_redis_cache.main[0].primary_access_key
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.main[0].primary_connection_string
  }

  type = "Opaque"
}

# Kubernetes Secret for Monitoring
resource "kubernetes_secret" "monitoring" {
  metadata {
    name      = "monitoring-secrets"
    namespace = kubernetes_namespace.shared.metadata[0].name
  }

  data = {
    WORKSPACE_ID  = azurerm_log_analytics_workspace.main.workspace_id
    WORKSPACE_KEY = azurerm_log_analytics_workspace.main.primary_shared_key
  }

  type = "Opaque"
}

# ConfigMap for Backend (Azure mode)
resource "kubernetes_config_map" "backend_azure" {
  count = var.deployment_mode == "azure" ? 1 : 0

  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.app_backend.metadata[0].name
    labels = {
      app         = "backend"
      environment = "azure"
    }
  }

  data = {
    FLASK_ENV                = "production"
    DATABASE_HOST            = azurerm_postgresql_flexible_server.main[0].fqdn
    DATABASE_PORT            = "5432"
    DATABASE_NAME            = "ai_saas_db"
    DATABASE_USER            = var.postgres_admin_username
    DATABASE_SSL_MODE        = "require"
    REDIS_HOST               = azurerm_redis_cache.main[0].hostname
    REDIS_PORT               = "6380"
    REDIS_SSL                = "true"
    STORAGE_TYPE             = "azure"
    AZURE_STORAGE_CONTAINER  = "uploaded-files"
    MAX_CONTENT_LENGTH       = "16777216"
    LOG_LEVEL                = "INFO"
  }
}

# Storage Class for Azure Files
resource "kubernetes_storage_class" "azurefile" {
  metadata {
    name = "azurefile-premium"
  }

  storage_provisioner = "file.csi.azure.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"

  parameters = {
    skuName = "Premium_LRS"
  }

  mount_options = [
    "dir_mode=0777",
    "file_mode=0777",
    "uid=0",
    "gid=0",
    "mfsymlinks",
    "cache=strict",
    "actimeo=30"
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Priority Class for Critical Workloads
resource "kubernetes_priority_class" "high_priority" {
  metadata {
    name = "high-priority"
  }

  value       = 1000
  description = "High priority class for critical application components"

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Network Policy - Allow backend to postgres (on-prem mode)
resource "kubernetes_network_policy" "backend_postgres" {
  count = var.deployment_mode == "onprem" ? 1 : 0

  metadata {
    name      = "allow-backend-to-postgres"
    namespace = kubernetes_namespace.app_backend.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "backend"
      }
    }

    policy_types = ["Ingress", "Egress"]

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "postgres"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }
  }
}

# Network Policy - Allow backend to redis (on-prem mode)
resource "kubernetes_network_policy" "backend_redis" {
  count = var.deployment_mode == "onprem" ? 1 : 0

  metadata {
    name      = "allow-backend-to-redis"
    namespace = kubernetes_namespace.app_backend.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "backend"
      }
    }

    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "redis"
          }
        }
      }

      ports {
        port     = "6379"
        protocol = "TCP"
      }
    }
  }
}
