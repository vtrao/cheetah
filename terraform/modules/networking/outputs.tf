# VPC ID output
output "vpc_id" {
  description = "VPC/VNet ID"
  value       = var.cloud_provider == "aws" ? (length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : null) : (var.cloud_provider == "gcp" ? (length(google_compute_network.main) > 0 ? google_compute_network.main[0].id : null) : null)
}

# Private subnet IDs
output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = var.cloud_provider == "aws" ? aws_subnet.private[*].id : (
    var.cloud_provider == "gcp" ? google_compute_subnetwork.private[*].id : []
  )
}

# Public subnet IDs  
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value = var.cloud_provider == "aws" ? aws_subnet.public[*].id : (
    var.cloud_provider == "gcp" ? google_compute_subnetwork.public[*].id : []
  )
}

# VPC CIDR block
output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.vpc_cidr
}

# Internet Gateway ID (AWS)
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = var.cloud_provider == "aws" ? (length(aws_internet_gateway.main) > 0 ? aws_internet_gateway.main[0].id : null) : null
}

# NAT Gateway IDs (AWS)
output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = var.cloud_provider == "aws" ? aws_nat_gateway.main[*].id : []
}
