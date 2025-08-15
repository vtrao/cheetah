# 🐆 Cheetah - Complete Infrastructure Platform

![Cheetah Logo](https://img.shields.io/badge/🐆-Cheetah-orange?style=for-the-badge)
![Cloud Agnostic](https://img.shields.io/badge/Cloud-Agnostic-blue?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)

**Cheetah** is a comprehensive, cloud-agnostic Infrastructure as Code (IaC) platform that provides production-ready infrastructure components for modern applications. Deploy Kubernetes clusters, managed databases, and networking infrastructure across AWS, GCP, and Azure with minimal configuration.

## 🚀 Quick Start

Get up and running in minutes:

```bash
git clone https://github.com/your-org/cheetah.git
cd cheetah
./scripts/quickstart.sh
```

That's it! Follow the interactive prompts to deploy your infrastructure.

## ✨ Features

### 🌐 **Cloud Agnostic**
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

### 🔒 **Security First**
- Least privilege IAM policies
- Network isolation
- Encryption at rest and in transit
- Security scanning integration

### 📊 **Observability**
- Integrated logging
- Metrics collection
- Health monitoring
- Alert management

## 🛠️ Prerequisites

- **Terraform** >= 1.0
- **kubectl** >= 1.20
- Cloud CLI tools:
  - AWS CLI (for AWS deployments)
  - gcloud CLI (for GCP deployments)
  - Azure CLI (for Azure deployments)

```
cheetah/
├── 📋 README.md                    # This file
├── ⚙️ terraform/                   # Terraform configurations
│   ├── main.tf                    # Main configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   └── modules/                   # Reusable modules
│       ├── 🌐 networking/         # VPC, subnets, security
│       ├── ☸️ kubernetes/         # K8s cluster configuration
│       └── 🗄️ database/           # Managed database setup
├── 📚 docs/                       # Documentation
│   ├── integration-guide.md       # How to integrate with existing projects
│   ├── architecture.md            # Architecture deep dive
│   └── troubleshooting.md         # Common issues and solutions
├── 🎯 examples/                   # Example configurations
│   ├── aws/                       # AWS-specific examples
│   ├── gcp/                       # GCP-specific examples
│   ├── azure/                     # Azure-specific examples
│   └── applications/              # Sample app deployments
└── �️ scripts/                    # Automation scripts
    ├── quickstart.sh              # Interactive setup
    ├── deploy.sh                  # Infrastructure deployment
    └── cleanup.sh                 # Resource cleanup
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Integration Guide](docs/integration-guide.md) | How to integrate Cheetah with your existing projects |
| [AWS Examples](examples/aws/README.md) | AWS-specific deployment examples |
| [GCP Examples](examples/gcp/README.md) | GCP-specific deployment examples |

## 🚦 Getting Started

### Option 1: Interactive Quick Start (Recommended)

```bash
./scripts/quickstart.sh
```

### Option 2: Manual Deployment

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
