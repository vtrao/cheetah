# 🐆 Cheetah - Complete Infrastructure & Deployment Platform

![Cheetah Logo](https://img.shields.io/badge/🐆-Cheetah-orange?style=for-the-badge)
![Cloud Agnostic](https://img.shields.io/badge/Cloud-Agnostic-blue?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)

**Cheetah** is a comprehensive, cloud-agnostic Infrastructure as Code (IaC) and deployment platform that provides production-ready infrastructure components and application deployment automation for modern applications. Deploy Kubernetes clusters, managed databases, networking infrastructure, and full-stack applications across AWS, GCP, and Azure with minimal configuration.

## 🚀 Quick Start

### Infrastructure Deployment
Get your infrastructure up and running in minutes:

```bash
git clone https://github.com/your-org/cheetah.git
cd cheetah
./scripts/quickstart.sh
```

### Application Deployment
Deploy your applications to existing infrastructure:

```bash
# Set your project configuration
export PROJECT_NAME="your-project"
export ENVIRONMENT="dev"

# Deploy your application
./deploy.sh
```

That's it! Follow the interactive prompts to deploy your infrastructure and applications.

## ✨ Features

### 🌐 **Cloud Agnostic Infrastructure**
- **AWS**: EKS, RDS, VPC
- **GCP**: GKE, Cloud SQL, VPC
- **Azure**: AKS, Azure Database, VNet *(coming soon)*

### ☸️ **Production-Ready Kubernetes**
- Auto-scaling node groups
- Network security policies
- RBAC configuration
- Service mesh ready
- Monitoring integration

### 🗄️ **Managed Databases**
- PostgreSQL with high availability
- Automated backups
- Security group configuration
- Connection pooling ready

### � **Application Deployment Automation**
- Template-based Kubernetes deployments
- Multi-architecture Docker builds
- Automated ECR/Registry authentication
- Database initialization and seeding
- Health check verification and monitoring
- Rolling updates with zero downtime

### 🏗️ **Application Templates**
- **FastAPI Python Backend**: REST API with health checks, database connectivity
- **React Frontend**: Modern React 18 with nginx proxy, API integration
- **Kubernetes Manifests**: Production-ready templates with security contexts
- **Docker Examples**: Multi-stage builds, non-root containers

### 🔧 **Built-in Best Practices**
- Non-root container execution
- Resource limits and requests
- Proper security contexts
- Health check endpoints
- Graceful shutdown handling
- Multi-platform support (AMD64/ARM64)

### �🔒 **Security First**
- Least privilege IAM policies
- Network isolation
- Encryption at rest and in transit
- Security scanning integration
- Secret management

### 📊 **Observability**
- Integrated logging
- Metrics collection
- Health monitoring
- Alert management

## 🛠️ Prerequisites

### Infrastructure Deployment
- **Terraform** >= 1.0
- **kubectl** >= 1.20
- Cloud CLI tools:
  - AWS CLI (for AWS deployments)
  - gcloud CLI (for GCP deployments)
  - Azure CLI (for Azure deployments)

### Application Deployment
- **Docker** installed and running
- **kubectl** configured for your cluster
- **AWS CLI** configured (for ECR authentication)

## 📁 Directory Structure

```
cheetah/
├── 📋 README.md                    # This file
├── 🚀 deploy.sh                    # Main application deployment script
├── ⚙️ terraform/                   # Terraform configurations
│   ├── main.tf                    # Main configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   └── modules/                   # Reusable modules
│       ├── 🌐 networking/         # VPC, subnets, security
│       ├── ☸️ kubernetes/         # K8s cluster configuration
│       └── 🗄️ database/           # Managed database setup
├── 🎯 scripts/                    # Deployment automation scripts
│   ├── deploy-apps.sh             # Application deployment
│   ├── customize-templates.sh     # Template processing
│   └── build-images.sh            # Docker image building
├── ☸️ kubernetes/                 # Kubernetes configurations
│   └── templates/                 # Reusable K8s manifests
│       ├── namespace.yaml
│       ├── backend-deployment.yaml
│       ├── frontend-deployment.yaml
│       ├── database-init-job.yaml
│       └── services.yaml
├── 📦 examples/                   # Application templates
│   ├── backend-python/           # FastAPI backend example
│   └── frontend-react/           # React frontend example
├── 📚 docs/                       # Documentation
│   ├── integration-guide.md       # How to integrate with existing projects
│   ├── architecture.md            # Architecture deep dive
│   └── troubleshooting.md         # Common issues and solutions
└── 🎯 examples/                   # Infrastructure examples
    ├── aws/                       # AWS-specific examples
    ├── gcp/                       # GCP-specific examples
    └── azure/                     # Azure-specific examples
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Integration Guide](docs/integration-guide.md) | How to integrate Cheetah with your existing projects |
| [AWS Examples](examples/aws/README.md) | AWS-specific deployment examples |
| [GCP Examples](examples/gcp/README.md) | GCP-specific deployment examples |
| [Application Templates](examples/README.md) | Guide to using application templates |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

## 🚦 Getting Started

### Option 1: Infrastructure Deployment (New Clusters)

```bash
# Interactive quick start for infrastructure
./scripts/quickstart.sh
```

### Option 2: Application Deployment (Existing Clusters)

```bash
# Set your project configuration
export PROJECT_NAME="your-project"
export ENVIRONMENT="dev"

# Deploy your application
./deploy.sh
```

### Option 3: Manual Infrastructure Deployment

1. **Choose your cloud provider and copy example configuration:**

```bash
# For AWS
cp examples/aws/terraform.tfvars terraform/terraform.tfvars

# For GCP
cp examples/gcp/terraform.tfvars terraform/terraform.tfvars
```

2. **Customize your configuration:**

```bash
vi terraform/terraform.tfvars
```

3. **Deploy infrastructure:**

```bash
./scripts/deploy.sh aws dev  # or gcp, azure
```

4. **Configure kubectl:**

```bash
export KUBECONFIG=terraform/kubeconfig-aws-dev.yaml
kubectl get nodes
```

### Application Template Usage

1. **Copy templates to your project:**
   ```bash
   cp -r infrastructure/cheetah/examples/* .
   ```

2. **Customize for your needs:**
   - Modify `backend/main.py` for your API logic
   - Update `frontend/src/App.js` for your UI
   - Adjust Kubernetes resource limits as needed

3. **Deploy:**
   ```bash
   ./infrastructure/cheetah/deploy.sh
   ```

## 🔧 Configuration

### Environment Variables
```bash
# Required for application deployment
export PROJECT_NAME="your-project-name"
export ENVIRONMENT="dev|staging|prod"

# Optional
export AWS_REGION="us-west-2"
export EKS_CLUSTER_NAME="your-cluster"
export CONTAINER_REGISTRY="your-registry"
```

### Template Customization
Templates use placeholder replacement:
- `{{PROJECT_NAME}}` - Your project identifier
- `{{ENVIRONMENT}}` - Deployment environment
- `{{CONTAINER_REGISTRY}}` - ECR registry URL
- `{{DB_PASSWORD}}` - Auto-generated secure password

## 🛠️ Advanced Features

### Multi-Architecture Support
Automatic detection and building for:
- linux/amd64 (Intel/AMD)
- linux/arm64 (ARM processors)

### Database Management
- Automatic PostgreSQL setup
- Schema initialization
- Sample data population
- Connection string management

### Health Monitoring
- Application readiness probes
- Liveness checks
- Database connectivity verification
- Automated rollback on failures

## 🐛 Troubleshooting

### Common Issues

**Architecture Mismatch:**
```bash
# Force specific architecture
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

**Database Connection:**
```bash
# Check database status
kubectl get pods -n your-project-dev
kubectl logs -f deployment/your-project-backend -n your-project-dev
```

**Image Pull Issues:**
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin your-registry
```

## 🗑️ Cleanup

**⚠️ Warning: This will destroy all infrastructure!**

```bash
./scripts/cleanup.sh aws dev
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Why Cheetah?

| Feature | Cheetah | Manual Setup | Other Tools |
|---------|---------|--------------|-------------|
| **Setup Time** | ⚡ 5 minutes | 🐌 Hours/Days | 🕐 30+ minutes |
| **Cloud Agnostic** | ✅ Yes | ❌ No | ⚠️ Limited |
| **Production Ready** | ✅ Yes | ⚠️ Depends | ⚠️ Basic |
| **Security Hardened** | ✅ Yes | ❌ Manual | ⚠️ Basic |
| **Documentation** | ✅ Comprehensive | ❌ DIY | ⚠️ Limited |

---

<div align="center">

**Made with ❤️ by the Cheetah Team**

🚀 **Ready to go fast? Deploy with Cheetah today!** 🐆

</div>

```
cheetah/
├── terraform/              # Core Terraform modules
├── kubernetes/             # K8s manifests and Helm charts
├── scripts/                # Automation scripts
├── examples/               # Example applications
├── docs/                   # Documentation
└── configs/                # Configuration templates
```

**Made with ❤️ for the DevOps community**
