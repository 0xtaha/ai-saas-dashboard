# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = true

  # Enable geo-replication for Premium SKU
  dynamic "georeplications" {
    for_each = var.acr_sku == "Premium" ? ["West US 2"] : []
    content {
      location = georeplications.value
      tags     = var.tags
    }
  }

  # Network rules
  network_rule_set {
    default_action = "Allow"
  }

  # Enable content trust
  trust_policy {
    enabled = true
  }

  # Retention policy for untagged manifests
  retention_policy {
    enabled = true
    days    = 7
  }

  tags = var.tags
}
