#!/bin/bash

# Cheetah Complete Deployment Script
# Usage: ./scripts/deploy.sh [cloud_provider] [environment] [project_name] [options]
# Options: --skip-infrastructure, --skip-images, --skip-apps

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[CHEETAH]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[CHEETAH]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[CHEETAH]${NC} $1"
}

print_error() {
    echo -e "${RED}[CHEETAH]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[CHEETAH]${NC} $1"
}

# Parse arguments
CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-dev}
PROJECT_NAME=${3:-proj}

# Parse options
SKIP_INFRASTRUCTURE=false
SKIP_IMAGES=false
SKIP_APPS=false

for arg in "${@:4}"; do
    case $arg in
        --skip-infrastructure)
            SKIP_INFRASTRUCTURE=true
            ;;
        --skip-images)
            SKIP_IMAGES=true
            ;;
        --skip-apps)
            SKIP_APPS=true
            ;;
        --help|-h)
            echo "Cheetah Complete Deployment Script"
            echo "Usage: $0 [cloud_provider] [environment] [project_name] [options]"
            echo ""
            echo "Arguments:"
            echo "  cloud_provider    aws|gcp|azure (default: aws)"
            echo "  environment      dev|staging|prod (default: dev)"
            echo "  project_name     Project name (default: proj)"
            echo ""
            echo "Options:"
            echo "  --skip-infrastructure  Skip Terraform infrastructure deployment"
            echo "  --skip-images          Skip Docker image building"
            echo "  --skip-apps            Skip Kubernetes application deployment"
            echo "  --help, -h             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 aws dev myproject"
            echo "  $0 aws dev myproject --skip-infrastructure"
            exit 0
            ;;
        *)
            print_warning "Unknown option: $arg"
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEETAH_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CHEETAH_ROOT")"
TERRAFORM_DIR="$CHEETAH_ROOT/terraform"

print_status "🐆 Starting Cheetah Complete Deployment..."
print_status "Cloud Provider: $CLOUD_PROVIDER"
print_status "Environment: $ENVIRONMENT"
print_status "Project Name: $PROJECT_NAME"
print_status "Project Root: $PROJECT_ROOT"
echo ""

# Validate inputs
if [[ ! "$CLOUD_PROVIDER" =~ ^(aws|gcp|azure)$ ]]; then
    print_error "Invalid cloud provider. Must be one of: aws, gcp, azure"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
fi

# Check dependencies
print_status "🔍 Checking dependencies..."
missing_deps=()

if ! command -v terraform &> /dev/null; then
    missing_deps+=("terraform")
fi

if ! command -v kubectl &> /dev/null; then
    missing_deps+=("kubectl")
fi

if ! command -v docker &> /dev/null; then
    missing_deps+=("docker")
fi

case $CLOUD_PROVIDER in
    aws)
        if ! command -v aws &> /dev/null; then
            missing_deps+=("aws cli")
        fi
        ;;
    gcp)
        if ! command -v gcloud &> /dev/null; then
            missing_deps+=("gcloud cli")
        fi
        ;;
    azure)
        if ! command -v az &> /dev/null; then
            missing_deps+=("azure cli")
        fi
        ;;
esac

if [ ${#missing_deps[@]} -gt 0 ]; then
    print_error "Missing dependencies: ${missing_deps[*]}"
    exit 1
fi

print_success "✅ All dependencies satisfied"

# Start deployment phases
DEPLOYMENT_START_TIME=$(date +%s)

# Phase 1: Infrastructure Deployment
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    print_status "🏗️  Phase 1: Infrastructure Deployment"
    echo "----------------------------------------"
    
    # Check if Terraform directory exists
    if [ ! -d "$TERRAFORM_DIR" ]; then
        print_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Create workspace if it doesn't exist
    terraform workspace new "$ENVIRONMENT" 2>/dev/null || terraform workspace select "$ENVIRONMENT"
    
    # Plan deployment
    print_status "Planning infrastructure changes..."
    terraform plan -var="environment=$ENVIRONMENT" -var="project_name=$PROJECT_NAME" -var="cloud_provider=$CLOUD_PROVIDER"
    
    # Apply infrastructure
    print_status "Applying infrastructure changes..."
    terraform apply -auto-approve -var="environment=$ENVIRONMENT" -var="project_name=$PROJECT_NAME" -var="cloud_provider=$CLOUD_PROVIDER"
    
    print_success "✅ Infrastructure deployment completed"
    echo ""
else
    print_warning "⏭️  Skipping infrastructure deployment"
fi

# Phase 2: Template Customization
print_status "🎨 Phase 2: Template Customization"
echo "-----------------------------------"

if [ -f "$SCRIPT_DIR/customize-templates.sh" ]; then
    "$SCRIPT_DIR/customize-templates.sh" "$PROJECT_NAME" "$ENVIRONMENT" "$CLOUD_PROVIDER"
    print_success "✅ Templates customized"
else
    print_warning "⚠️  Template customization script not found"
fi
echo ""

# Phase 3: Docker Image Building
if [ "$SKIP_IMAGES" = false ]; then
    print_status "🐳 Phase 3: Docker Image Building"
    echo "----------------------------------"
    
    if [ -f "$SCRIPT_DIR/build-images.sh" ]; then
        "$SCRIPT_DIR/build-images.sh" "$PROJECT_NAME" "$ENVIRONMENT" "$CLOUD_PROVIDER"
        print_success "✅ Docker images built and pushed"
    else
        print_warning "⚠️  Build images script not found, skipping..."
    fi
    echo ""
else
    print_warning "⏭️  Skipping Docker image building"
fi

# Phase 4: Application Deployment
if [ "$SKIP_APPS" = false ]; then
    print_status "🚀 Phase 4: Application Deployment"
    echo "-----------------------------------"
    
    if [ -f "$SCRIPT_DIR/deploy-apps.sh" ]; then
        "$SCRIPT_DIR/deploy-apps.sh" "$ENVIRONMENT" "$CLOUD_PROVIDER" "$PROJECT_NAME"
        print_success "✅ Applications deployed"
    else
        print_error "Application deployment script not found"
        exit 1
    fi
    echo ""
else
    print_warning "⏭️  Skipping application deployment"
fi

# Deployment Summary
DEPLOYMENT_END_TIME=$(date +%s)
DEPLOYMENT_DURATION=$((DEPLOYMENT_END_TIME - DEPLOYMENT_START_TIME))

print_success "🎉 Cheetah Deployment Completed Successfully!"
echo "=============================================="
print_info "📊 Deployment Summary:"
echo "  • Project: $PROJECT_NAME"
echo "  • Environment: $ENVIRONMENT"
echo "  • Cloud Provider: $CLOUD_PROVIDER"
echo "  • Duration: ${DEPLOYMENT_DURATION}s"
echo ""

# Show access information
case $CLOUD_PROVIDER in
    aws)
        print_info "🔗 Access Information:"
        if command -v aws &> /dev/null; then
            CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
            REGION=$(aws configure get region || echo "us-east-1")
            echo "  • Cluster: $CLUSTER_NAME"
            echo "  • Region: $REGION"
            echo "  • Update kubeconfig: aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION"
        fi
        ;;
