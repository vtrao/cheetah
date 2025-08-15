# Cheetah Examples

This directory contains example configurations and use cases for the Cheetah infrastructure platform.

## Directory Structure

```
examples/
├── aws/                    # AWS-specific examples
│   ├── terraform.tfvars   # Example AWS configuration
│   └── README.md          # AWS deployment guide
├── gcp/                    # GCP-specific examples
│   ├── terraform.tfvars   # Example GCP configuration
│   └── README.md          # GCP deployment guide
├── azure/                  # Azure-specific examples
│   ├── terraform.tfvars   # Example Azure configuration
│   └── README.md          # Azure deployment guide
└── applications/           # Sample application deployments
    ├── web-app/           # Simple web application
    ├── microservices/     # Microservices architecture
    └── ml-pipeline/       # Machine learning pipeline
```

## Quick Start Examples

### 1. Simple Web Application (3-tier architecture)

```bash
# Deploy infrastructure
cd cheetah
./scripts/quickstart.sh

# Deploy sample web app
kubectl apply -f examples/applications/web-app/
```

### 2. Microservices Architecture

```bash
# Deploy with load balancer and service mesh
cd terraform
terraform apply -var="enable_service_mesh=true"

# Deploy microservices
kubectl apply -f examples/applications/microservices/
```

### 3. Machine Learning Pipeline

```bash
# Deploy with GPU nodes
cd terraform
terraform apply -var="enable_gpu_nodes=true"

# Deploy ML pipeline
kubectl apply -f examples/applications/ml-pipeline/
```

## Configuration Examples

### Development Environment
- Single availability zone
- Smaller instance types
- Basic monitoring
- Cost-optimized

### Staging Environment
- Multi-availability zone
- Production-like setup
- Enhanced monitoring
- Load testing ready

### Production Environment
- High availability
- Auto-scaling
- Comprehensive monitoring
- Security hardened
- Backup enabled

## Cloud Provider Specific Features

### AWS
- EKS with Fargate option
- RDS with Multi-AZ
- CloudWatch integration
- IAM roles for service accounts

### GCP
- GKE with Autopilot option
- Cloud SQL with high availability
- Cloud Monitoring integration
- Workload Identity

### Azure
- AKS with Virtual Nodes
- Azure Database for PostgreSQL
- Azure Monitor integration
- Azure AD integration

## Best Practices

1. **Resource Naming**: Use consistent naming conventions
2. **Tagging**: Apply proper tags for cost tracking
3. **Security**: Follow principle of least privilege
4. **Monitoring**: Enable comprehensive logging and metrics
5. **Backup**: Configure automated backups for databases

## Cost Optimization

- Use spot instances for non-critical workloads
- Configure auto-scaling policies
- Set up budget alerts
- Regular resource cleanup
- Monitor usage patterns

## Next Steps

After deploying your infrastructure:

1. Configure kubectl access
2. Set up CI/CD pipelines
3. Deploy monitoring stack
4. Configure backup policies
5. Set up alerting rules

For detailed deployment instructions, see the cloud-specific README files in each subdirectory.
