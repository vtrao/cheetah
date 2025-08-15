terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Provider configurations
provider "aws" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  region = var.region
}

provider "google" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project_id
  region  = var.region
}

# Local values for consistent naming
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "cheetah"
    CloudProvider = var.cloud_provider
  }
}

# Networking module
module "networking" {
  source = "./modules/networking"
  
  cloud_provider = var.cloud_provider
  region         = var.region
  name_prefix    = local.name_prefix
  
  # VPC configuration
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  
  tags = local.common_tags
}

# Kubernetes cluster module
module "kubernetes" {
  source = "./modules/kubernetes"
  
  cloud_provider = var.cloud_provider
  region         = var.region
  name_prefix    = local.name_prefix
  
  # Cluster configuration
  kubernetes_version = var.kubernetes_version
  node_groups        = var.node_groups
  
  # Networking
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  
  # GCP specific
  gcp_project_id = var.gcp_project_id
  
  tags = local.common_tags
  
  depends_on = [module.networking]
}

# Database module
module "database" {
  source = "./modules/database"
  
  cloud_provider = var.cloud_provider
  region         = var.region
  name_prefix    = local.name_prefix
  
  # Database configuration
  engine                = var.database_config.engine
  engine_version        = var.database_config.engine_version
  instance_class        = var.database_config.instance_class
  allocated_storage     = var.database_config.allocated_storage
  database_name         = var.database_config.database_name
  master_username       = var.database_config.master_username
  master_password       = var.database_config.master_password
  
  # Networking
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  # Security
  allowed_security_groups = [module.kubernetes.worker_security_group_id]
  
  # GCP specific
  gcp_project_id = var.gcp_project_id
  
  tags = local.common_tags
  
  depends_on = [module.networking, module.kubernetes]
}

# Monitoring module (optional)
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  cloud_provider = var.cloud_provider
  region         = var.region
  name_prefix    = local.name_prefix
  
  # Cluster info
  cluster_name = module.kubernetes.cluster_name
  
  # GCP specific
  gcp_project_id = var.gcp_project_id
  
  tags = local.common_tags
  
  depends_on = [module.kubernetes]
}
