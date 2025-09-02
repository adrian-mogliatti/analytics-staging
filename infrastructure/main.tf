resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = { env = "staging" project = var.prefix }
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags = { env = "staging" }
}

resource "azurerm_app_service_plan" "plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

# Backend App Service (container)
resource "azurerm_app_service" "backend" {
  name                = var.backend_app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  https_only          = true

  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-samples/node-hello-world:latest"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
    "WEBSITE_RUN_FROM_PACKAGE"        = "0"
  }
}

# Proxy App Service (serves frontend static + proxies /api to backend; enforces Basic Auth)
resource "azurerm_app_service" "proxy" {
  name                = var.proxy_app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  https_only          = true

  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/nginx:stable-alpine" 
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
    "BASIC_AUTH_USER"                 = var.basic_auth_user
    "BASIC_AUTH_PASS"                 = var.basic_auth_pass
  }
}

# Application Insights
resource "azurerm_application_insights" "ai" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# Action Group (email)
resource "azurerm_monitor_action_group" "ag" {
  name                = "${var.prefix}-actiongroup"
  short_name          = "ag"
  resource_group_name = azurerm_resource_group.rg.name
  email_receiver {
    name          = "admin"
    email_address = var.admin_email
  }
}

# Metric alert: CPU > 70% for backend
resource "azurerm_monitor_metric_alert" "backend_cpu" {
  name                = "${var.prefix}-backend-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_app_service.backend.id]
  description         = "Alert when backend CPU > 70%"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

# Metric alert: CPU > 70% for proxy
resource "azurerm_monitor_metric_alert" "proxy_cpu" {
  name                = "${var.prefix}-proxy-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_app_service.proxy.id]
  description         = "Alert when proxy CPU > 70%"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

