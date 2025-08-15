# Core configuration
variable "cloud_provider" {
  description = "Cloud provider to deploy to (aws, gcp, azure)"
  type        = string
  validation {
    condition     = contains(["aws", "gcp", "azure"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, gcp, azure."
  }
}

variable "region" {
  description = "Cloud provider region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# GCP specific
variable "gcp_project_id" {
  description = "GCP project ID (required when cloud_provider is gcp)"
  type        = string
  default     = ""
}

# Networking configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Kubernetes configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "node_groups" {
  description = "Configuration for Kubernetes node groups"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
  }))
  default = {
    main = {
      instance_types = ["t3.medium"]  # AWS default, will be mapped for other clouds
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 50
    }
  }
}

# Database configuration
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine            = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    database_name     = string
    master_username   = string
    master_password   = string
  })
  default = {
    engine            = "postgres"
    engine_version    = "13.7"
    instance_class    = "small"  # Will be mapped to cloud-specific instance types
    allocated_storage = 20
    database_name     = "appdb"
    master_username   = "dbadmin"
    master_password   = "changeme123!"  # Should be overridden
  }
}

# Application configuration
variable "app_config" {
  description = "Application configuration"
  type = object({
    image             = string
    tag               = string
    replicas          = number
    port              = number
    health_check_path = string
    resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
  })
  default = {
    image             = "nginx"
    tag               = "latest"
    replicas          = 2
    port              = 80
    health_check_path = "/"
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}

# Optional features
variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ingress controller"
  type        = bool
  default     = true
}
