# Random password for PostgreSQL
resource "random_password" "postgres" {
  count   = var.deployment_mode == "azure" ? 1 : 0
  length  = 32
  special = true
}

# Azure Database for PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  count               = var.deployment_mode == "azure" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-postgres"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  administrator_login    = var.postgres_admin_username
  administrator_password = random_password.postgres[0].result

  sku_name   = var.postgres_sku_name
  version    = var.postgres_version
  storage_mb = var.postgres_storage_mb

  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  delegated_subnet_id = azurerm_subnet.postgres[0].id
  private_dns_zone_id = azurerm_private_dns_zone.postgres[0].id

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 3
    start_minute = 0
  }

  tags = var.tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.deployment_mode == "azure" ? 1 : 0
  name      = "ai_saas_db"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# PostgreSQL Firewall Rule - Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count            = var.deployment_mode == "azure" ? 1 : 0
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Configuration - Enable extensions
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  count     = var.deployment_mode == "azure" ? 1 : 0
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  value     = "pg_stat_statements,pgcrypto,uuid-ossp"
}

# PostgreSQL Configuration - Connection settings
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  count     = var.deployment_mode == "azure" ? 1 : 0
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  value     = "200"
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_buffers" {
  count     = var.deployment_mode == "azure" ? 1 : 0
  name      = "shared_buffers"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  value     = "524288" # 512MB in 8KB pages
}
