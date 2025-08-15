# AWS Example Configuration
cloud_provider = "aws"
region         = "us-west-2"
project_name   = "cheetah-demo"
environment    = "dev"

# Networking
vpc_cidr                = "10.0.0.0/16"
availability_zones      = ["us-west-2a", "us-west-2b"]
private_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs     = ["10.0.101.0/24", "10.0.102.0/24"]

# Kubernetes
kubernetes_version = "1.28"
node_groups = [
  {
    name           = "general"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 3
    desired_size   = 2
    launch_template = null
  }
]

# Database
database_config = {
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  database_name     = "app_db"
  master_username   = "postgres"
  master_password   = "" # Will be auto-generated
}

# Optional features
enable_monitoring = true
