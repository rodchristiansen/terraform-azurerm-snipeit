variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "snipeit-rg"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "Canada Central"
}

variable "app_name_prefix" {
  description = "Prefix for the application name (will be appended with random suffix)"
  type        = string
  default     = "snipeit"
}

variable "app_url" {
  description = "The full URL where the Snipe-IT application will be accessible"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_prefix" {
  description = "Address prefix for the app service subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "mysql_subnet_prefix" {
  description = "Address prefix for the MySQL flexible server subnet"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

# Database Configuration
variable "mysql_admin_username" {
  description = "Administrator username for MySQL server"
  type        = string
  default     = "snipeitadmin"
  sensitive   = true
}

variable "mysql_version" {
  description = "MySQL server version"
  type        = string
  default     = "8.0.21"
}

variable "mysql_sku_name" {
  description = "SKU for MySQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_storage_size_gb" {
  description = "Storage size in GB for MySQL server"
  type        = number
  default     = 20
}

variable "mysql_storage_iops" {
  description = "Storage IOPS for MySQL server"
  type        = number
  default     = 360
}

variable "mysql_zone" {
  description = "Availability zone for MySQL server"
  type        = string
  default     = "1"
}

variable "mysql_database_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "snipeit"
}

# Storage Configuration
variable "storage_account_tier" {
  description = "Performance tier of the storage account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage replication type must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS"
  }
}

variable "storage_share_quota" {
  description = "Maximum size of the storage shares in GB"
  type        = number
  default     = 50
}

# App Service Configuration
variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B2"
}

variable "docker_image" {
  description = "Docker image for Snipe-IT"
  type        = string
  default     = "index.docker.io/snipe/snipe-it:latest"
}

# Application Settings
variable "app_timezone" {
  description = "Application timezone"
  type        = string
  default     = "UTC"
}

variable "app_locale" {
  description = "Application locale"
  type        = string
  default     = "en-US"
}

variable "app_debug" {
  description = "Enable debug mode (should be false in production)"
  type        = bool
  default     = false
}

# Mail Configuration
variable "mail_from_address" {
  description = "Email address to send emails from"
  type        = string
}

variable "mail_from_name" {
  description = "Name to display in sent emails"
  type        = string
  default     = "Snipe-IT Admin"
}

variable "sendgrid_enabled" {
  description = "Enable SendGrid for email delivery"
  type        = bool
  default     = true
}

# Key Vault Configuration
variable "key_vault_sku" {
  description = "SKU for the Key Vault"
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault"
  type        = number
  default     = 7
  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days"
  }
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

# SCIM Configuration
variable "scim_standards_compliance" {
  description = "Enable SCIM standards compliance"
  type        = bool
  default     = true
}

variable "scim_trace" {
  description = "Enable SCIM tracing for debugging"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "Snipe-IT"
  }
}

# Certificate Configuration
variable "mysql_ssl_cert_base64" {
  description = "Base64-encoded MySQL SSL certificate (DigiCert Global Root CA)"
  type        = string
  default     = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURyekNDQXBlZ0F3SUJBZ0lRQ0R2Z1ZwQkNSckdoZFdySldaSEhTakFOQmdrcWhraUc5dzBCQVFVRkFEQmgKTVFzd0NRWURWUVFHRXdKVlV6RVZNQk1HQTFVRUNoTU1SR2xuYVVObGNuUWdTVzVqTVJrd0Z3WURWUVFMRXhCMwpkM2N1WkdsbmFXTmxjblF1WTI5dE1TQXdIZ1lEVlFRREV4ZEVhV2RwUTJWeWRDQkhiRzlpWVd3Z1VtOXZkQ0JEClFUQWVGdzB3TmpFeE1UQXdNREF3TURCYUZ3MHpNVEV4TVRBd01EQXdNREJhTUdFeEN6QUpCZ05WQkFZVEFsVlQKTVJVd0V3WURWUVFLRXd4RWFXZHBRMlZ5ZENCSmJtTXhHVEFYQmdOVkJBc1RFSGQzZHk1a2FXZHBZMlZ5ZEM1agpiMjB4SURBZUJnTlZCQU1URjBScFoybERaWEowSUVkc2IySmhiQ0JTYjI5MElFTkJNSUlCSWpBTkJna3Foa2lHCjl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUE0anZoRVhMZXFLVFRvMWVxVUtLUEMzZVF5YUtsN2hMT2xsc0IKQ1NETUFaT25UakMzVS9kRHhHa0FWNTNpalNMZGh3WkFBSUVKenM0Ymc3L2Z6VHR4UnVMV1pzY0ZzM1luRm85NwpuaDZWZmU2M1NLTUkydGF2ZWd3NUJtVi9TbDBmdkJmNHE3N3VLTmQwZjNwNG1WbUZhRzVjSXpKTHYwN0E2RnB0CjQzQy9keEMvL0FIMmhkbW9SQkJZTXFsMUdOWFJvcjVINGlkcTlKb3orRWtJWUl2VVg3UTZoTCtocWtwTWZUN1AKVDE5c2RsNmdTemVSbnR3aTVtM09GQnFPYXN2K3piTVVaQmZIV3ltZU1yL3k3dnJUQzBMVXE3ZEJNdG9NMU8vNApnZFc3alZnL3RSdm9TU2lpY05veEJOMzNzaGJ5VEFwT0I2anRTajFldGframtNT3ZKd0lEQVFBQm8yTXdZVEFPCkJnTlZIUThCQWY4RUJBTUNBWVl3RHdZRFZSMFRBUUgvQkFVd0F3RUIvekFkQmdOVkhRNEVGZ1FVQTk1UU5WYlIKVEx0bThLUGlHeHZEbDdJOTBWVXdId1lEVlIwakJCZ3dGb0FVQTk1UU5WYlJUTHRtOEtQaUd4dkRsN0k5MFZVdwpEUVlKS29aSWh2Y05BUUVGQlFBRGdnRUJBTXVjTjZwSUV4SUsrdDFFbkU5U3NQVGZyZ1QxZVhrSW95UVkvRXNyCmhNQXR1ZFhIL3ZUQkgxakx1RzJjZW5Ubm1DbXJFYlhqY0tDaHpVeUltWk9Na1hEaXF3OGN2cE9wLzJQVjVBZGcKMDZPL25Wc0o4ZFdPNDFQMGptUDZQNmZidEdiZlltYlcwVzVCamZJdHRlcDNTcCtkV09JcldjQkFJKzB0S0lKRgpQbmxVa2lhWTRJQklxRGZ2OE5aNVlCYmVyT2dPelc2c1JCYzRMMG5hNFVVK0tyazJVODg2VUFiM0x1akVWMGxzCllTRVkxUVN0ZUR3c09vQnJwK3V2RlJUcDJJbkJ1VGhzNHBGc2l2OWt1WGNsVnpEQUd5U2o0ZHpwMzBkOHRiUWsKQ0FVdzdDMjlDNzlGdjFDNXFmUHJtQUVTcmNpSXhwZzBYNDBLUE1icDFaV1ZiZDQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
}

# Secret Names in Key Vault
variable "keyvault_secret_db_password" {
  description = "Name of the Key Vault secret containing the database admin password"
  type        = string
  default     = "db-admin-password"
}

variable "keyvault_secret_app_key" {
  description = "Name of the Key Vault secret containing the application key"
  type        = string
  default     = "app-key"
}

variable "keyvault_secret_sendgrid_api_key" {
  description = "Name of the Key Vault secret containing the SendGrid API key"
  type        = string
  default     = "sendgrid-api-key"
}
