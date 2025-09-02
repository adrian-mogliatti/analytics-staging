output "proxy_hostname" {
  value = azurerm_app_service.proxy.default_site_hostname
}

output "backend_hostname" {
  value = azurerm_app_service.backend.default_site_hostname
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

# Do not output the admin password here (sensitive) – it's available in Terraform state.

