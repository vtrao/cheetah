# HashiCorp Vault Integration (Optional Advanced Setup)
# This configuration adds Vault as a centralized secret management solution

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

# Vault provider configuration
provider "vault" {
  # Vault address should be set via VAULT_ADDR environment variable
  # Vault token should be set via VAULT_TOKEN environment variable
  
  # For production, use proper auth methods like AWS IAM, GCP IAM, or Azure AD
  # auth_login {
  #   path = "auth/aws"
  #   parameters = {
  #     role = "terraform-role"
  #   }
  # }
}

# Vault secret engine for database credentials
resource "vault_mount" "database" {
  count = var.enable_vault ? 1 : 0
  path  = "database"
  type  = "database"
  
  description = "Database secrets engine for ${var.project_name}"
}

# Vault database connection for PostgreSQL
resource "vault_database_connection" "postgres" {
  count   = var.enable_vault && var.database_config.engine == "postgres" ? 1 : 0
  backend = vault_mount.database[0].path
  name    = "${var.project_name}-${var.environment}-postgres"

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${module.database.database_endpoint}:5432/${var.database_config.database_name}"
    username       = var.database_config.master_username
    password       = var.database_config.master_password
  }
  
  allowed_roles = ["${var.project_name}-${var.environment}-app"]
}

# Vault database role for application
resource "vault_database_role" "app_role" {
  count    = var.enable_vault ? 1 : 0
  backend  = vault_mount.database[0].path
  name     = "${var.project_name}-${var.environment}-app"
  db_name  = vault_database_connection.postgres[0].name
  
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;",
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]
  
  default_ttl = 3600    # 1 hour
  max_ttl     = 86400   # 24 hours
}

# Vault policy for Kubernetes service accounts
resource "vault_policy" "k8s_app_policy" {
  count = var.enable_vault ? 1 : 0
  name  = "${var.project_name}-${var.environment}-k8s-policy"

  policy = <<EOT
# Allow reading database credentials
path "database/creds/${vault_database_role.app_role[0].name}" {
  capabilities = ["read"]
}

# Allow reading static secrets
path "secret/data/${var.project_name}/${var.environment}/*" {
  capabilities = ["read"]
}
EOT
}

# Vault Kubernetes auth method
resource "vault_auth_backend" "kubernetes" {
  count = var.enable_vault ? 1 : 0
  type  = "kubernetes"
  path  = "kubernetes-${var.environment}"
}

resource "vault_kubernetes_auth_backend_config" "k8s_config" {
  count                = var.enable_vault ? 1 : 0
  backend              = vault_auth_backend.kubernetes[0].path
  kubernetes_host      = module.kubernetes.cluster_endpoint
  kubernetes_ca_cert   = base64decode(module.kubernetes.cluster_certificate_authority_data)
  token_reviewer_jwt   = data.kubernetes_secret.vault_token.data.token
}

# Vault role for Kubernetes service accounts
resource "vault_kubernetes_auth_backend_role" "app_role" {
  count                            = var.enable_vault ? 1 : 0
  backend                          = vault_auth_backend.kubernetes[0].path
  role_name                        = "${var.project_name}-${var.environment}-app"
  bound_service_account_names      = ["${var.project_name}-app"]
  bound_service_account_namespaces = ["${var.project_name}-app"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.k8s_app_policy[0].name]
}
