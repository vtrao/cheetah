#!/bin/bash

# Cheetah Deployment Script
# Usage: ./scripts/deploy.sh [aws|gcp] [environment]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if correct number of arguments
if [ $# -lt 1 ]; then
    print_error "Usage: $0 [aws|gcp] [environment]"
    print_error "Example: $0 aws dev"
    exit 1
fi

CLOUD_PROVIDER=$1
ENVIRONMENT=${2:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

print_status "🐆 Starting Cheetah deployment..."
print_status "Cloud Provider: $CLOUD_PROVIDER"
print_status "Environment: $ENVIRONMENT"

# Validate cloud provider
if [[ ! "$CLOUD_PROVIDER" =~ ^(aws|gcp|azure)$ ]]; then
    print_error "Invalid cloud provider. Must be one of: aws, gcp, azure"
    exit 1
fi

# Check prerequisites
print_status "Checking prerequisites..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. You won't be able to manage the cluster directly."
fi

# Check cloud provider CLI
case $CLOUD_PROVIDER in
    aws)
        if ! command -v aws &> /dev/null; then
            print_error "AWS CLI is not installed. Please install AWS CLI first."
            exit 1
        fi
        
        # Check AWS credentials
        if ! aws sts get-caller-identity &> /dev/null; then
            print_error "AWS credentials not configured. Please run 'aws configure' first."
            exit 1
        fi
        print_success "AWS credentials validated"
        ;;
    gcp)
        if ! command -v gcloud &> /dev/null; then
            print_error "Google Cloud CLI is not installed. Please install gcloud first."
            exit 1
        fi
        
        # Check GCP authentication
        if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 &> /dev/null; then
            print_error "GCP credentials not configured. Please run 'gcloud auth login' first."
            exit 1
        fi
        print_success "GCP credentials validated"
        ;;
    azure)
        if ! command -v az &> /dev/null; then
            print_error "Azure CLI is not installed. Please install Azure CLI first."
            exit 1
        fi
        
        # Check Azure authentication
        if ! az account show &> /dev/null; then
            print_error "Azure credentials not configured. Please run 'az login' first."
            exit 1
        fi
        print_success "Azure credentials validated"
        ;;
esac

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Copy example tfvars if it doesn't exist
TFVARS_FILE="terraform.tfvars"
EXAMPLE_TFVARS="../examples/$CLOUD_PROVIDER/terraform.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    if [ -f "$EXAMPLE_TFVARS" ]; then
        print_status "Copying example configuration for $CLOUD_PROVIDER..."
        cp "$EXAMPLE_TFVARS" "$TFVARS_FILE"
        print_warning "Please review and update $TFVARS_FILE before continuing"
        print_warning "Press Enter to continue or Ctrl+C to abort..."
        read -r
    else
        print_error "Example configuration not found: $EXAMPLE_TFVARS"
        exit 1
    fi
fi

# Initialize Terraform
print_status "Initializing Terraform..."
if terraform init; then
    print_success "Terraform initialized successfully"
else
    print_error "Terraform initialization failed"
    exit 1
fi

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform configuration validation failed"
    exit 1
fi

# Plan deployment
print_status "Planning deployment..."
if terraform plan -var="environment=$ENVIRONMENT" -out=tfplan; then
    print_success "Terraform plan completed successfully"
else
    print_error "Terraform planning failed"
    exit 1
fi

# Ask for confirmation
echo
print_warning "Review the plan above carefully."
print_warning "This will create real cloud resources that may incur costs."
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply deployment
print_status "Applying deployment..."
if terraform apply tfplan; then
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed"
    exit 1
fi

# Clean up plan file
rm -f tfplan

# Get outputs
print_status "Retrieving deployment information..."

CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "Not available")
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint 2>/dev/null || echo "Not available")
DATABASE_ENDPOINT=$(terraform output -raw database_endpoint 2>/dev/null || echo "Not available")

echo
print_success "🎉 Deployment Summary:"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Cluster Endpoint: $CLUSTER_ENDPOINT"
echo "  Database Endpoint: $DATABASE_ENDPOINT"
echo

# Generate kubeconfig
if command -v kubectl &> /dev/null; then
    print_status "Generating kubeconfig..."
    
    KUBECONFIG_FILE="kubeconfig-$CLOUD_PROVIDER-$ENVIRONMENT.yaml"
    
    if terraform output -raw kubeconfig > "$KUBECONFIG_FILE" 2>/dev/null; then
        print_success "Kubeconfig saved to: $KUBECONFIG_FILE"
        print_status "To use kubectl with this cluster, run:"
        echo "  export KUBECONFIG=$PWD/$KUBECONFIG_FILE"
        echo "  kubectl get nodes"
    else
        print_warning "Could not generate kubeconfig"
    fi
fi

echo
print_success "🚀 Cheetah infrastructure deployed successfully!"
print_status "Next steps:"
echo "  1. Configure kubectl with the generated kubeconfig"
echo "  2. Deploy your applications to the cluster"
echo "  3. Set up monitoring and alerting"
echo "  4. Configure CI/CD pipelines"

# Show cost estimation reminder
print_warning "💰 Remember: Cloud resources incur costs. Monitor your usage and clean up when not needed."
print_status "To destroy this infrastructure later, run: terraform destroy"

echo
print_status "For more information, see: https://github.com/your-org/cheetah/docs"
