# Generate random suffix for globally unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  # Generate globally unique names by combining prefix with random suffix
  app_name            = "${var.app_name_prefix}-${random_id.suffix.hex}"
  storage_account_name = lower(replace("${var.app_name_prefix}${random_id.suffix.hex}", "-", ""))
  key_vault_name      = "${var.app_name_prefix}-kv-${random_id.suffix.hex}"
}

# Data Source to fetch the current client config
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "assets" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "assets_vnet" {
  name                = "${var.app_name_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.assets.location
  resource_group_name = azurerm_resource_group.assets.name
  tags                = var.tags
}

# Subnet for general assets
resource "azurerm_subnet" "assets_subnet" {
  name                 = "${var.app_name_prefix}-app-subnet"
  resource_group_name  = azurerm_resource_group.assets.name
  virtual_network_name = azurerm_virtual_network.assets_vnet.name
  address_prefixes     = var.app_subnet_prefix

  delegation {
    name = "webappDelegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for MySQL flexible server
resource "azurerm_subnet" "mysql_flexible_server_subnet" {
  name                 = "${var.app_name_prefix}-mysql-subnet"
  resource_group_name  = azurerm_resource_group.assets.name
  virtual_network_name = azurerm_virtual_network.assets_vnet.name
  address_prefixes     = var.mysql_subnet_prefix
  delegation {
    name = "mysqlDelegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Key Vault
resource "azurerm_key_vault" "assets_inventory_credentials" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.assets.location
  resource_group_name         = azurerm_resource_group.assets.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.key_vault_sku
  soft_delete_retention_days  = var.key_vault_soft_delete_retention_days
  purge_protection_enabled    = var.key_vault_purge_protection_enabled
  tags                        = var.tags

  # Grant access to the current service principal/user running Terraform
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

# Key Vault Secrets
# Note: These secrets must be created manually in the Key Vault before running this Terraform
data "azurerm_key_vault_secret" "db_admin_password" {
  name         = var.keyvault_secret_db_password
  key_vault_id = azurerm_key_vault.assets_inventory_credentials.id
  depends_on   = [azurerm_key_vault.assets_inventory_credentials]
}

data "azurerm_key_vault_secret" "app_key" {
  name         = var.keyvault_secret_app_key
  key_vault_id = azurerm_key_vault.assets_inventory_credentials.id
  depends_on   = [azurerm_key_vault.assets_inventory_credentials]
}

data "azurerm_key_vault_secret" "sendgrid_api_key" {
  name         = var.keyvault_secret_sendgrid_api_key
  key_vault_id = azurerm_key_vault.assets_inventory_credentials.id
  depends_on   = [azurerm_key_vault.assets_inventory_credentials]
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "assets_inventory_db" {
  name                   = "${var.app_name_prefix}-mysql-${random_id.suffix.hex}"
  resource_group_name    = azurerm_resource_group.assets.name
  location               = azurerm_resource_group.assets.location
  administrator_login    = var.mysql_admin_username
  administrator_password = data.azurerm_key_vault_secret.db_admin_password.value
  tags                   = var.tags
  zone                   = var.mysql_zone
  sku_name               = var.mysql_sku_name
  
  storage {
    iops    = var.mysql_storage_iops
    size_gb = var.mysql_storage_size_gb
  }
  
  version = var.mysql_version
  
  delegated_subnet_id = azurerm_subnet.mysql_flexible_server_subnet.id
}

# MySQL Flexible Database
resource "azurerm_mysql_flexible_database" "snipeit_db" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_mysql_flexible_server.assets_inventory_db.resource_group_name
  server_name         = azurerm_mysql_flexible_server.assets_inventory_db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
  depends_on          = [azurerm_mysql_flexible_server.assets_inventory_db]
}

# Storage Account
resource "azurerm_storage_account" "snipeit_storage_account" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.assets.name
  location                 = azurerm_resource_group.assets.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                     = var.tags
}

# Storage Share for Snipe IT
resource "azurerm_storage_share" "snipeit" {
  name                 = "snipeit"
  storage_account_name = azurerm_storage_account.snipeit_storage_account.name
  quota                = var.storage_share_quota
}

# Storage Share Logs for Snipe IT
resource "azurerm_storage_share" "snipeit_logs" {
  name                 = "snipeit-logs"
  storage_account_name = azurerm_storage_account.snipeit_storage_account.name
  quota                = var.storage_share_quota
}


# DigiCertGlobalRootCA.crt.pem DB certificate to File Share

resource "null_resource" "write_cert" {
  triggers = {
    cert_base64 = var.mysql_ssl_cert_base64
  }

  provisioner "local-exec" {
    command = "echo '${var.mysql_ssl_cert_base64}' | base64 --decode > ${path.module}/DigiCertGlobalRootCA.crt.pem"
  }
}

resource "azurerm_storage_share_file" "cert_file" {
  name             = "DigiCertGlobalRootCA.crt.pem"
  storage_share_id = azurerm_storage_share.snipeit.id
  source           = "${path.module}/DigiCertGlobalRootCA.crt.pem"

  depends_on = [null_resource.write_cert]
}


# MySQL Flexible Server Configuration for innodb_buffer_pool_load_at_startup
resource "azurerm_mysql_flexible_server_configuration" "innodb_load_at_startup" {
  name                = "innodb_buffer_pool_load_at_startup"
  server_name         = azurerm_mysql_flexible_server.assets_inventory_db.name
  resource_group_name = azurerm_mysql_flexible_server.assets_inventory_db.resource_group_name
  value               = "OFF"
}

# MySQL Flexible Server Configuration for innodb_buffer_pool_dump_at_shutdown
resource "azurerm_mysql_flexible_server_configuration" "innodb_dump_at_shutdown" {
  name                = "innodb_buffer_pool_dump_at_shutdown"
  server_name         = azurerm_mysql_flexible_server.assets_inventory_db.name
  resource_group_name = azurerm_mysql_flexible_server.assets_inventory_db.resource_group_name
  value               = "OFF"
}

# MySQL Flexible Server Configuration for sql_generate_invisible_primary_key
resource "azurerm_mysql_flexible_server_configuration" "sql_invisible_primary_key" {
  name                = "sql_generate_invisible_primary_key"
  server_name         = azurerm_mysql_flexible_server.assets_inventory_db.name
  resource_group_name = azurerm_mysql_flexible_server.assets_inventory_db.resource_group_name
  value               = "OFF"
}

# Service Plan for Azure App Service
resource "azurerm_service_plan" "assets_inventory_plan" {
  name                = "${var.app_name_prefix}-plan-${random_id.suffix.hex}"
  location            = azurerm_resource_group.assets.location
  resource_group_name = azurerm_resource_group.assets.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = var.tags
}

# Resources for Azure App Service
resource "azurerm_linux_web_app" "assets_inventory_app" {
  name                      = local.app_name
  resource_group_name       = azurerm_resource_group.assets.name
  location                  = azurerm_resource_group.assets.location
  service_plan_id           = azurerm_service_plan.assets_inventory_plan.id
  virtual_network_subnet_id = azurerm_subnet.assets_subnet.id

  site_config {
    ftps_state                = "Disabled"
    http2_enabled             = "true"

    application_stack {
      docker_image_name   = var.docker_image
    }
  }

  storage_account {
    name         = "snipeit"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.snipeit_storage_account.name
    share_name   = azurerm_storage_share.snipeit.name
    access_key   = azurerm_storage_account.snipeit_storage_account.primary_access_key
    mount_path   = "/var/lib/snipeit"
  }

  storage_account {
    name         = "snipeit-logs"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.snipeit_storage_account.name
    share_name   = azurerm_storage_share.snipeit_logs.name
    access_key   = azurerm_storage_account.snipeit_storage_account.primary_access_key
    mount_path   = "/var/www/html/storage/logs"
  }

  app_settings = merge(
    {
      "APP_KEY"                             = data.azurerm_key_vault_secret.app_key.value
      "APP_URL"                             = var.app_url
      "APP_TIMEZONE"                        = var.app_timezone
      "APP_ENV"                             = var.environment
      "APP_DEBUG"                           = var.app_debug
      "APP_LOCALE"                          = var.app_locale
      "MYSQL_DATABASE"                      = var.mysql_database_name
      "MYSQL_USER"                          = azurerm_mysql_flexible_server.assets_inventory_db.administrator_login
      "MYSQL_PASSWORD"                      = data.azurerm_key_vault_secret.db_admin_password.value
      "DB_CONNECTION"                       = "mysql"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = true
      "MYSQL_PORT_3306_TCP_ADDR"            = azurerm_mysql_flexible_server.assets_inventory_db.fqdn
      "MYSQL_PORT_3306_TCP_PORT"            = "3306"
      "DB_SSL_IS_PAAS"                      = true
      "DB_SSL"                              = true
      "DB_SSL_CA_PATH"                      = "/var/lib/snipeit/DigiCertGlobalRootCA.crt.pem"
      "SCIM_STANDARDS_COMPLIANCE"           = var.scim_standards_compliance
      "SCIM_TRACE"                          = var.scim_trace
    },
    var.sendgrid_enabled ? {
      "MAIL_DRIVER"             = "smtp"
      "MAIL_ENV_ENCRYPTION"     = "tcp"
      "MAIL_PORT_587_TCP_ADDR"  = "smtp.sendgrid.net"
      "MAIL_PORT_587_TCP_PORT"  = "587"
      "MAIL_ENV_USERNAME"       = "apikey"
      "MAIL_ENV_PASSWORD"       = data.azurerm_key_vault_secret.sendgrid_api_key.value
      "MAIL_ENV_FROM_ADDR"      = var.mail_from_address
      "MAIL_ENV_FROM_NAME"      = var.mail_from_name
    } : {}
  )

  https_only = true
}


# Allow MySQL traffic to the virtual network
resource "azurerm_network_security_rule" "allow_mysql_from_vnet" {
  name                        = "assets-allow-mysql-from-vnet"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_network_security_group.assets_vnet_nsg.resource_group_name
  network_security_group_name = azurerm_network_security_group.assets_vnet_nsg.name
}

# Control inbound and outbound network traffic to resources in the vnet
resource "azurerm_network_security_group" "assets_vnet_nsg" {
  name                = "${var.app_name_prefix}-nsg"
  location            = azurerm_resource_group.assets.location
  resource_group_name = azurerm_resource_group.assets.name
  tags                = var.tags

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-mysql"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.app_subnet_prefix[0]
    destination_address_prefix = var.mysql_subnet_prefix[0]
  }
}

# Associates the defined Network Security Group (NSG) with a specific subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.assets_subnet.id
  network_security_group_id = azurerm_network_security_group.assets_vnet_nsg.id
}

# Integrates an Azure App Service with a subnet within a virtual network
resource "azurerm_app_service_virtual_network_swift_connection" "assets_connection" {
  app_service_id = azurerm_linux_web_app.assets_inventory_app.id
  subnet_id      = azurerm_subnet.assets_subnet.id
}
