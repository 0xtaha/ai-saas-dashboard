# Azure Cache for Redis
resource "azurerm_redis_cache" "main" {
  count               = var.deployment_mode == "azure" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku

  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  # Premium SKU features
  shard_count = var.redis_sku == "Premium" ? 2 : null

  redis_configuration {
    enable_authentication           = true
    maxmemory_reserved              = 50
    maxmemory_delta                 = 50
    maxmemory_policy                = "allkeys-lru"
    notify_keyspace_events          = ""
    rdb_backup_enabled              = var.redis_sku == "Premium" ? true : false
    rdb_backup_frequency            = var.redis_sku == "Premium" ? 60 : null
    rdb_backup_max_snapshot_count   = var.redis_sku == "Premium" ? 1 : null
    rdb_storage_connection_string   = var.redis_sku == "Premium" ? azurerm_storage_account.redis_backup[0].primary_blob_connection_string : null
  }

  # Patch schedule (maintenance window)
  patch_schedule {
    day_of_week    = "Sunday"
    start_hour_utc = 3
  }

  # Private endpoint for Redis (Premium SKU)
  subnet_id = var.redis_sku == "Premium" ? azurerm_subnet.redis[0].id : null

  tags = var.tags
}

# Storage Account for Redis backups (Premium only)
resource "azurerm_storage_account" "redis_backup" {
  count                    = var.deployment_mode == "azure" && var.redis_sku == "Premium" ? 1 : 0
  name                     = "${replace(var.project_name, "-", "")}${var.environment}redis"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = var.tags
}

# Redis Firewall Rule - Allow Azure Services
resource "azurerm_redis_firewall_rule" "azure_services" {
  count               = var.deployment_mode == "azure" && var.redis_sku != "Premium" ? 1 : 0
  name                = "allow-azure-services"
  redis_cache_name    = azurerm_redis_cache.main[0].name
  resource_group_name = azurerm_resource_group.main.name
  start_ip            = "0.0.0.0"
  end_ip              = "0.0.0.0"
}

# Private Endpoint for Redis (Premium SKU)
resource "azurerm_private_endpoint" "redis" {
  count               = var.deployment_mode == "azure" && var.redis_sku == "Premium" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-redis-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.redis[0].id

  private_service_connection {
    name                           = "${var.project_name}-redis-connection"
    private_connection_resource_id = azurerm_redis_cache.main[0].id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  tags = var.tags
}
