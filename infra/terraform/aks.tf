# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = "1.28"

  default_node_pool {
    name                = "system"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = true
    min_count           = var.aks_min_node_count
    max_count           = var.aks_max_node_count
    os_disk_size_gb     = 128
    type                = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "33%"
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/24"
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
  }

  # Enable monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Enable Azure AD integration
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
  }

  # Enable workload identity for pod identities
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags
}

# Application Node Pool (for application workloads)
resource "azurerm_kubernetes_cluster_node_pool" "application" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D4s_v3"
  node_count            = 2
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 8
  vnet_subnet_id        = azurerm_subnet.aks.id
  os_disk_size_gb       = 128

  node_labels = {
    "workload-type" = "application"
  }

  node_taints = []

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# Monitoring Node Pool (for monitoring workloads)
resource "azurerm_kubernetes_cluster_node_pool" "monitoring" {
  name                  = "monitoring"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2s_v3"
  node_count            = 2
  enable_auto_scaling   = false
  vnet_subnet_id        = azurerm_subnet.aks.id
  os_disk_size_gb       = 64

  node_labels = {
    "workload-type" = "monitoring"
  }

  node_taints = [
    "monitoring=true:NoSchedule"
  ]

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# Role Assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Role Assignment for AKS to manage network
resource "azurerm_role_assignment" "aks_network" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.main.id
}
