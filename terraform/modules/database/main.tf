# Database Module - Cloud Agnostic Managed PostgreSQL

# AWS RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
    Type = "db-subnet-group"
  })
}

# AWS RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  family = "postgres15"
  name   = "${var.name_prefix}-db-params"
  
  parameter {
    name  = "log_statement"
    value = "all"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  
  tags = var.tags
}

# AWS RDS Security Group
resource "aws_security_group" "rds" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
    Type = "security-group"
  })
}

# AWS RDS Instance
resource "aws_db_instance" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  identifier     = "${var.name_prefix}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  parameter_group_name   = aws_db_parameter_group.main[0].name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"
  
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name_prefix}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Enhanced monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring[0].arn
  
  # Performance insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  # Deletion protection for production
  deletion_protection = var.environment == "prod" ? true : false
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db"
    Type = "rds-instance"
  })
}

# AWS IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name = "${var.name_prefix}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# GCP Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name                = "${var.name_prefix}-db"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = var.environment == "prod" ? true : false
  
  settings {
    tier              = var.instance_class
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.allocated_storage
    disk_autoresize   = true
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_id
      enable_private_path_for_google_cloud_services = true
    }
    
    database_flags {
      name  = "log_statement"
      value = "all"
    }
    
    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }
    
    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }
    
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
    }
  }
}

# GCP Cloud SQL Database
resource "google_sql_database" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name     = var.database_name
  instance = google_sql_database_instance.main[0].name
}

# GCP Cloud SQL User
resource "google_sql_user" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name     = var.master_username
  instance = google_sql_database_instance.main[0].name
  password = var.master_password
}

# GCP Private Service Connection (for private IP)
resource "google_compute_global_address" "private_ip_address" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name          = "${var.name_prefix}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

# Random password generation (if not provided)
resource "random_password" "master_password" {
  count = var.master_password == "" ? 1 : 0
  
  length  = 16
  special = true
}

# Local values
locals {
  final_master_password = var.master_password != "" ? var.master_password : random_password.master_password[0].result
}
