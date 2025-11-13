# Azure Storage Account for Blob Storage (Azure mode only)
resource "azurerm_storage_account" "main" {
  count                    = var.deployment_mode == "azure" ? 1 : 0
  name                     = "${replace(var.project_name, "-", "")}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant storage
  account_kind             = "StorageV2"

  # Enable blob features
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  # Security settings
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  # Network rules
  network_rules {
    default_action             = "Allow"  # Change to "Deny" for production with VNet integration
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.aks.id]
  }

  tags = var.tags
}

# Blob Container for Uploaded Files
resource "azurerm_storage_container" "uploaded_files" {
  count                 = var.deployment_mode == "azure" ? 1 : 0
  name                  = "uploaded-files"
  storage_account_name  = azurerm_storage_account.main[0].name
  container_access_type = "private"
}

# Optional: Lifecycle Management Policy
resource "azurerm_storage_management_policy" "main" {
  count              = var.deployment_mode == "azure" ? 1 : 0
  storage_account_id = azurerm_storage_account.main[0].id

  rule {
    name    = "archive-old-files"
    enabled = true

    filters {
      prefix_match = ["uploaded-files/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }

      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }
}

# Private Endpoint for Blob Storage (Optional but recommended for production)
resource "azurerm_private_endpoint" "blob" {
  count               = var.deployment_mode == "azure" && var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-blob-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.aks.id

  private_service_connection {
    name                           = "${var.project_name}-blob-connection"
    private_connection_resource_id = azurerm_storage_account.main[0].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  count               = var.deployment_mode == "azure" && var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.deployment_mode == "azure" && var.enable_private_endpoints ? 1 : 0
  name                  = "${var.project_name}-blob-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = var.tags
}

# DNS A Record for Private Endpoint
resource "azurerm_private_dns_a_record" "blob" {
  count               = var.deployment_mode == "azure" && var.enable_private_endpoints ? 1 : 0
  name                = azurerm_storage_account.main[0].name
  zone_name           = azurerm_private_dns_zone.blob[0].name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.blob[0].private_service_connection[0].private_ip_address]
  tags                = var.tags
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = var.deployment_mode == "azure" ? 1 : 0
  name                       = "${var.project_name}-storage-diagnostics"
  target_resource_id         = "${azurerm_storage_account.main[0].id}/blobServices/default/"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}
