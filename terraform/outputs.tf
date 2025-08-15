# Cluster outputs
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.kubernetes.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes cluster"
  value       = module.kubernetes.cluster_endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = module.kubernetes.kubeconfig
  sensitive   = true
}

# Database outputs
output "database_endpoint" {
  description = "Database endpoint"
  value       = module.database.endpoint
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = module.database.port
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

# Networking outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

# Application deployment commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value = var.cloud_provider == "aws" ? (
    "aws eks update-kubeconfig --region ${var.region} --name ${module.kubernetes.cluster_name}"
  ) : var.cloud_provider == "gcp" ? (
    "gcloud container clusters get-credentials ${module.kubernetes.cluster_name} --region ${var.region} --project ${var.gcp_project_id}"
  ) : "# Configure kubectl for your cloud provider"
}

output "database_connection_string" {
  description = "Database connection string template"
  value = "postgresql://${var.database_config.master_username}:[PASSWORD]@${module.database.endpoint}:${module.database.port}/${module.database.database_name}"
  sensitive = true
}

# Quick deployment guide
output "next_steps" {
  description = "Next steps to deploy your application"
  value = <<-EOT
    
    🎉 Infrastructure deployed successfully!
    
    Next steps:
    1. Configure kubectl:
       ${var.cloud_provider == "aws" ? "aws eks update-kubeconfig --region ${var.region} --name ${module.kubernetes.cluster_name}" : var.cloud_provider == "gcp" ? "gcloud container clusters get-credentials ${module.kubernetes.cluster_name} --region ${var.region} --project ${var.gcp_project_id}" : "Configure kubectl for your cloud provider"}
    
    2. Verify cluster access:
       kubectl get nodes
    
    3. Deploy your application:
       kubectl apply -f ../examples/simple-webapp/
    
    4. Get database connection details:
       terraform output database_connection_string
    
    Happy coding! 🚀
  EOT
}
