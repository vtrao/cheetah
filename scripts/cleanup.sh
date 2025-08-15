#!/bin/bash

# Cheetah Cleanup Script
# Usage: ./scripts/cleanup.sh [aws|gcp] [environment]

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

print_warning "🐆 Starting Cheetah infrastructure cleanup..."
print_warning "Cloud Provider: $CLOUD_PROVIDER"
print_warning "Environment: $ENVIRONMENT"

# Validate cloud provider
if [[ ! "$CLOUD_PROVIDER" =~ ^(aws|gcp|azure)$ ]]; then
    print_error "Invalid cloud provider. Must be one of: aws, gcp, azure"
    exit 1
fi

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    print_error "No Terraform state found. Nothing to clean up."
    exit 1
fi

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi

# Show what will be destroyed
print_status "Planning destruction..."
if ! terraform plan -destroy -var="environment=$ENVIRONMENT" -out=destroy.tfplan; then
    print_error "Failed to create destruction plan"
    exit 1
fi

echo
print_warning "⚠️  DANGER ZONE ⚠️"
print_warning "This will PERMANENTLY DELETE all infrastructure resources!"
print_warning "This includes:"
echo "  • Kubernetes clusters and all workloads"
echo "  • Databases and ALL DATA"
echo "  • Load balancers and networking"
echo "  • Storage volumes and snapshots"
echo "  • IAM roles and policies"
echo

# Multiple confirmations for safety
print_error "This action CANNOT be undone!"
read -p "Are you absolutely sure you want to destroy all resources? (type 'DELETE' to confirm): " -r
echo

if [[ ! $REPLY == "DELETE" ]]; then
    print_status "Cleanup cancelled - staying safe!"
    rm -f destroy.tfplan
    exit 0
fi

print_warning "Last chance to abort!"
read -p "Type the environment name '$ENVIRONMENT' to confirm: " -r
echo

if [[ ! $REPLY == "$ENVIRONMENT" ]]; then
    print_status "Cleanup cancelled - environment name didn't match"
    rm -f destroy.tfplan
    exit 0
fi

# Apply destruction
print_status "Destroying infrastructure..."
print_warning "This may take several minutes..."

if terraform apply destroy.tfplan; then
    print_success "Infrastructure destroyed successfully"
else
    print_error "Destruction failed - some resources may still exist"
    print_warning "Check your cloud console and clean up manually if needed"
    exit 1
fi

# Clean up local files
rm -f destroy.tfplan
rm -f kubeconfig-*.yaml

# Optional: Clean up terraform state
print_status "Cleaning up local state files..."
read -p "Do you want to remove local Terraform state files? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf .terraform/
    rm -f terraform.tfstate*
    rm -f .terraform.lock.hcl
    print_success "Local state files removed"
else
    print_status "Local state files preserved"
fi

echo
print_success "🧹 Cleanup completed!"
print_status "All Cheetah infrastructure has been removed"

# Cloud-specific cleanup reminders
case $CLOUD_PROVIDER in
    aws)
        print_status "AWS cleanup reminders:"
        echo "  • Check for any remaining EBS snapshots"
        echo "  • Verify CloudWatch logs are cleaned up"
        echo "  • Check S3 buckets for any remaining data"
        ;;
    gcp)
        print_status "GCP cleanup reminders:"
        echo "  • Check for any persistent disks"
        echo "  • Verify Cloud Storage buckets are empty"
        echo "  • Check Cloud Logging for any remaining logs"
        ;;
    azure)
        print_status "Azure cleanup reminders:"
        echo "  • Check for any unattached disks"
        echo "  • Verify storage accounts are cleaned up"
        echo "  • Check Azure Monitor for any remaining data"
        ;;
esac

print_warning "💰 Don't forget to check your cloud bill to ensure all resources are stopped!"
