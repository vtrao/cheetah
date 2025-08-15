# Integrating Your Application with Cheetah

This guide shows how to integrate your existing application with the Cheetah infrastructure platform.

## Overview

Cheetah provides cloud-agnostic infrastructure that your application can leverage through:
1. **Git Submodule Integration** - Include Cheetah as a submodule
2. **Infrastructure Configuration** - Define your infrastructure needs
3. **Kubernetes Manifests** - Deploy your application to the provisioned cluster
4. **CI/CD Pipeline** - Automate deployment workflows

## Step 1: Add Cheetah as a Submodule

In your application repository:

```bash
# Add Cheetah as a git submodule
git submodule add https://github.com/your-org/cheetah.git infrastructure/cheetah

# Initialize the submodule
git submodule update --init --recursive
```

Your project structure will look like:

```
your-app/
├── backend/
├── frontend/
├── docker-compose.yml
├── infrastructure/
│   ├── cheetah/                 # Git submodule
│   ├── main.tf                  # Your infrastructure config
│   ├── terraform.tfvars         # Environment-specific values
│   └── kubernetes/              # Your K8s manifests
│       ├── backend.yaml
│       ├── frontend.yaml
│       └── database-secret.yaml
└── .github/workflows/           # CI/CD pipelines
```

## Step 2: Create Infrastructure Configuration

Create `infrastructure/main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    # Configure your state backend
    bucket = "your-terraform-state-bucket"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

# Use Cheetah platform
module "platform" {
  source = "./cheetah/terraform"
  
  # Core configuration
  cloud_provider = var.cloud_provider
  region         = var.region
  project_name   = var.project_name
  environment    = var.environment
  
  # GCP specific (if using GCP)
  gcp_project_id = var.gcp_project_id
  
  # Networking
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  
  # Kubernetes
  kubernetes_version = var.kubernetes_version
  node_groups        = var.node_groups
  
  # Database
  database_config = var.database_config
  
  # Features
  enable_monitoring = var.enable_monitoring
}

# Configure Kubernetes provider with cluster info
provider "kubernetes" {
  host                   = module.platform.cluster_endpoint
  cluster_ca_certificate = base64decode(module.platform.cluster_certificate_authority_data)
  
  # AWS EKS
  dynamic "exec" {
    for_each = var.cloud_provider == "aws" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.platform.cluster_name]
    }
  }
  
  # GCP GKE
  dynamic "exec" {
    for_each = var.cloud_provider == "gcp" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

# Create Kubernetes namespace for your application
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.project_name
    labels = {
      name        = var.project_name
      environment = var.environment
    }
  }
}

# Create database secret for your application
resource "kubernetes_secret" "database" {
  metadata {
    name      = "database-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  data = {
    DB_HOST     = module.platform.database_endpoint
    DB_PORT     = module.platform.database_port
    DB_NAME     = module.platform.database_name
    DB_USER     = module.platform.database_username
    DB_PASSWORD = module.platform.database_password
    DATABASE_URL = module.platform.database_connection_string
  }
  
  type = "Opaque"
}
```

## Step 3: Create Variables File

Create `infrastructure/variables.tf`:

```hcl
variable "cloud_provider" {
  description = "Cloud provider (aws, gcp, azure)"
  type        = string
}

variable "region" {
  description = "Cloud provider region"
  type        = string
}

variable "project_name" {
  description = "Name of your project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID (required for GCP)"
  type        = string
  default     = ""
}

# Include all other variables from Cheetah
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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Node group configurations"
  type = list(object({
    name           = string
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    launch_template = optional(object({
      id      = string
      version = string
    }))
  }))
}

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
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}
```

## Step 4: Environment-Specific Configuration

Create `infrastructure/terraform.tfvars` for your environment:

```hcl
# For AWS deployment
cloud_provider = "aws"
region         = "us-west-2"
project_name   = "ideas-app"
environment    = "prod"

# Kubernetes configuration
kubernetes_version = "1.28"
node_groups = [
  {
    name           = "general"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 10
    desired_size   = 3
    launch_template = null
  }
]

# Database configuration  
database_config = {
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.small"
  allocated_storage = 50
  database_name     = "ideas_db"
  master_username   = "postgres"
  master_password   = "" # Auto-generated
}

enable_monitoring = true
```

## Step 5: Create Kubernetes Manifests

Create `infrastructure/kubernetes/backend.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: ideas-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: your-registry/ideas-backend:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: DATABASE_URL
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: ideas-app
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: ClusterIP
```

Create `infrastructure/kubernetes/frontend.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ideas-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: your-registry/ideas-frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ideas-app
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

## Step 6: CI/CD Pipeline

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-west-2
  ECR_REPOSITORY_BACKEND: ideas-backend
  ECR_REPOSITORY_FRONTEND: ideas-frontend

jobs:
  infrastructure:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
      with:
        submodules: recursive
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Init
      run: terraform init
      working-directory: ./infrastructure
    
    - name: Terraform Plan
      run: terraform plan
      working-directory: ./infrastructure
    
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve
      working-directory: ./infrastructure
    
    - name: Get kubeconfig
      if: github.ref == 'refs/heads/main'
      run: |
        terraform output -raw kubeconfig > kubeconfig.yaml
        echo "KUBECONFIG=$(pwd)/kubeconfig.yaml" >> $GITHUB_ENV
      working-directory: ./infrastructure

  build-and-deploy:
    needs: infrastructure
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
    
    - name: Login to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build and push backend image
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY_BACKEND:$GITHUB_SHA ./backend
        docker push $ECR_REGISTRY/$ECR_REPOSITORY_BACKEND:$GITHUB_SHA
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
    
    - name: Build and push frontend image
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY_FRONTEND:$GITHUB_SHA ./frontend
        docker push $ECR_REGISTRY/$ECR_REPOSITORY_FRONTEND:$GITHUB_SHA
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
    
    - name: Deploy to Kubernetes
      run: |
        # Update image tags in manifests
        sed -i "s|your-registry/ideas-backend:latest|$ECR_REGISTRY/$ECR_REPOSITORY_BACKEND:$GITHUB_SHA|g" infrastructure/kubernetes/backend.yaml
        sed -i "s|your-registry/ideas-frontend:latest|$ECR_REGISTRY/$ECR_REPOSITORY_FRONTEND:$GITHUB_SHA|g" infrastructure/kubernetes/frontend.yaml
        
        # Apply manifests
        kubectl apply -f infrastructure/kubernetes/
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
```

## Step 7: Deploy Your Application

1. **Initialize Infrastructure**:
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

2. **Get Kubeconfig**:
```bash
terraform output -raw kubeconfig > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml
```

3. **Build and Push Images**:
```bash
# Tag and push your images to ECR/GCR
docker build -t your-registry/ideas-backend:v1.0.0 ./backend
docker build -t your-registry/ideas-frontend:v1.0.0 ./frontend

docker push your-registry/ideas-backend:v1.0.0
docker push your-registry/ideas-frontend:v1.0.0
```

4. **Deploy Application**:
```bash
kubectl apply -f kubernetes/
kubectl get pods -n ideas-app
kubectl get services -n ideas-app
```

## Benefits of This Integration

1. **Infrastructure as Code**: Version-controlled, repeatable infrastructure
2. **Cloud Agnostic**: Easy to switch between cloud providers
3. **Production Ready**: Security, monitoring, and scalability built-in
4. **Automated**: CI/CD pipeline handles deployment
5. **Modular**: Reuse Cheetah across multiple projects

## Next Steps

- Set up monitoring dashboards
- Configure alerts and notifications
- Implement blue-green deployments
- Add additional environments (staging, dev)
- Explore advanced Kubernetes features (Istio, ArgoCD)

This integration transforms your simple Docker Compose application into a production-ready, cloud-native solution!
