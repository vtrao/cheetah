# AWS Systems Manager Parameter Store integration for Terraform
# This data source retrieves the database password from AWS SSM Parameter Store

data "aws_ssm_parameter" "db_password" {
  count           = var.cloud_provider == "aws" ? 1 : 0
  name            = "/${var.project_name}/${var.environment}/database/password"
  with_decryption = true
}

data "aws_ssm_parameter" "app_secret_key" {
  count           = var.cloud_provider == "aws" ? 1 : 0  
  name            = "/${var.project_name}/${var.environment}/app/secret-key"
  with_decryption = true
}

# GCP Secret Manager integration
data "google_secret_manager_secret_version" "db_password" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  secret = "${var.project_name}-${var.environment}-db-password"
}

data "google_secret_manager_secret_version" "app_secret_key" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  secret = "${var.project_name}-${var.environment}-app-secret"
}

# Azure Key Vault integration
data "azurerm_key_vault" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-kv"
  resource_group_name = "${var.project_name}-${var.environment}-rg"
}

data "azurerm_key_vault_secret" "db_password" {
  count        = var.cloud_provider == "azure" ? 1 : 0
  name         = "database-password"
  key_vault_id = data.azurerm_key_vault.main[0].id
}

data "azurerm_key_vault_secret" "app_secret_key" {
  count        = var.cloud_provider == "azure" ? 1 : 0
  name         = "app-secret-key"
  key_vault_id = data.azurerm_key_vault.main[0].id
}
