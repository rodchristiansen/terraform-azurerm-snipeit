# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.assets.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.assets.location
}

# App Service
output "app_service_name" {
  description = "The name of the App Service"
  value       = azurerm_linux_web_app.assets_inventory_app.name
}

output "app_service_default_hostname" {
  description = "The default hostname of the App Service"
  value       = azurerm_linux_web_app.assets_inventory_app.default_hostname
}

output "app_service_url" {
  description = "The URL of the Snipe-IT application"
  value       = "https://${azurerm_linux_web_app.assets_inventory_app.default_hostname}"
}

output "app_service_id" {
  description = "The ID of the App Service"
  value       = azurerm_linux_web_app.assets_inventory_app.id
}

# MySQL Database
output "mysql_server_name" {
  description = "The name of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.assets_inventory_db.name
}

output "mysql_server_fqdn" {
  description = "The FQDN of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.assets_inventory_db.fqdn
}

output "mysql_database_name" {
  description = "The name of the MySQL database"
  value       = azurerm_mysql_flexible_database.snipeit_db.name
}

output "mysql_admin_username" {
  description = "The administrator username for MySQL server"
  value       = azurerm_mysql_flexible_server.assets_inventory_db.administrator_login
  sensitive   = true
}

# Storage Account
output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.snipeit_storage_account.name
}

output "storage_account_id" {
  description = "The ID of the storage account  "
  value       = azurerm_storage_account.snipeit_storage_account.id
}

output "storage_account_primary_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = azurerm_storage_account.snipeit_storage_account.primary_blob_endpoint
}

# Key Vault
output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.assets_inventory_credentials.name
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.assets_inventory_credentials.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.assets_inventory_credentials.vault_uri
}

# Network
output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.assets_vnet.name
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.assets_vnet.id
}

output "app_subnet_id" {
  description = "The ID of the app service subnet"
  value       = azurerm_subnet.assets_subnet.id
}

output "mysql_subnet_id" {
  description = "The ID of the MySQL subnet"
  value       = azurerm_subnet.mysql_flexible_server_subnet.id
}

# App Service Plan
output "app_service_plan_name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.assets_inventory_plan.name
}

output "app_service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.assets_inventory_plan.id
}

# Important Notes
output "post_deployment_instructions" {
  description = "Important post-deployment instructions"
  value       = <<-EOT
    IMPORTANT: Before the application can start, you must manually add the following secrets to Key Vault '${azurerm_key_vault.assets_inventory_credentials.name}':
    
    1. ${var.keyvault_secret_db_password}: The MySQL administrator password (used for database authentication)
    2. ${var.keyvault_secret_app_key}: The Snipe-IT application key (generate with: php artisan key:generate)
    3. ${var.keyvault_secret_sendgrid_api_key}: Your SendGrid API key (if using SendGrid for email)
    
    Your Snipe-IT application will be available at: https://${azurerm_linux_web_app.assets_inventory_app.default_hostname}
    
    You can also configure a custom domain by updating the 'app_url' variable and adding a custom domain to the App Service.
  EOT
}
