output "database_endpoint" {
  description = "Database endpoint"
  value = var.cloud_provider == "aws" ? aws_db_instance.main[0].endpoint : google_sql_database_instance.main[0].private_ip_address
}

output "database_port" {
  description = "Database port"
  value = var.cloud_provider == "aws" ? aws_db_instance.main[0].port : 5432
}

output "database_name" {
  description = "Database name"
  value = var.database_name
}

output "database_username" {
  description = "Database username"
  value = var.master_username
}

output "database_password" {
  description = "Database password"
  value = local.final_master_password
  sensitive = true
}

output "database_connection_string" {
  description = "Database connection string"
  value = format(
    "postgresql://%s:%s@%s:%s/%s",
    var.master_username,
    local.final_master_password,
    var.cloud_provider == "aws" ? aws_db_instance.main[0].endpoint : google_sql_database_instance.main[0].private_ip_address,
    var.cloud_provider == "aws" ? aws_db_instance.main[0].port : 5432,
    var.database_name
  )
  sensitive = true
}

output "database_security_group_id" {
  description = "Security group ID for the database (AWS only)"
  value = var.cloud_provider == "aws" ? aws_security_group.rds[0].id : null
}

output "database_instance_id" {
  description = "Database instance identifier"
  value = var.cloud_provider == "aws" ? aws_db_instance.main[0].id : google_sql_database_instance.main[0].name
}

output "database_arn" {
  description = "Database ARN (AWS only)"
  value = var.cloud_provider == "aws" ? aws_db_instance.main[0].arn : null
}
