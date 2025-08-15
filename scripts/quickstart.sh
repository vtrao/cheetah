#!/bin/bash

# Cheetah Quick Start Script
# This script helps you get started with Cheetah quickly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║                                       ║"
    echo "  ║              🐆 CHEETAH 🐆            ║"
    echo "  ║        Cloud-Agnostic Infrastructure  ║"
    echo "  ║                                       ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

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

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

clear
print_header

echo "Welcome to Cheetah! Let's get your cloud infrastructure set up quickly."
echo

# Step 1: Choose cloud provider
print_step "1. Choose your cloud provider"
echo "   1) AWS"
echo "   2) Google Cloud Platform (GCP)"
echo "   3) Microsoft Azure"
echo

while true; do
    read -p "Enter your choice (1-3): " choice
    case $choice in
        1)
            CLOUD_PROVIDER="aws"
            CLOUD_NAME="AWS"
            break
            ;;
        2)
            CLOUD_PROVIDER="gcp"
            CLOUD_NAME="Google Cloud Platform"
            break
            ;;
        3)
            CLOUD_PROVIDER="azure"
            CLOUD_NAME="Microsoft Azure"
            break
            ;;
        *)
            print_error "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac
done

print_success "Selected: $CLOUD_NAME"
echo

# Step 2: Choose environment
print_step "2. Choose your environment"
echo "   Common options: dev, staging, prod"
echo

read -p "Enter environment name (default: dev): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-dev}
print_success "Environment: $ENVIRONMENT"
echo

# Step 3: Prerequisites check
print_step "3. Checking prerequisites..."

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r .terraform_version 2>/dev/null || terraform version | head -n1 | cut -d' ' -f2)
    print_success "Terraform found: $TERRAFORM_VERSION"
else
    print_error "Terraform not found!"
    echo "Please install Terraform from: https://www.terraform.io/downloads"
    exit 1
fi

# Check cloud CLI
case $CLOUD_PROVIDER in
    aws)
        if command -v aws &> /dev/null; then
            print_success "AWS CLI found"
            # Check credentials
            if aws sts get-caller-identity &> /dev/null; then
                ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                REGION=$(aws configure get region || echo "us-east-1")
                print_success "AWS credentials configured (Account: $ACCOUNT_ID, Region: $REGION)"
            else
                print_error "AWS credentials not configured"
                echo "Please run: aws configure"
                exit 1
            fi
        else
            print_error "AWS CLI not found!"
            echo "Please install AWS CLI from: https://aws.amazon.com/cli/"
            exit 1
        fi
        ;;
    gcp)
        if command -v gcloud &> /dev/null; then
            print_success "Google Cloud CLI found"
            # Check authentication
            if ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1) && [ -n "$ACCOUNT" ]; then
                PROJECT=$(gcloud config get-value project 2>/dev/null || echo "Not set")
                print_success "GCP authenticated (Account: $ACCOUNT, Project: $PROJECT)"
                if [ "$PROJECT" = "Not set" ]; then
                    print_warning "No default project set. You may need to run: gcloud config set project YOUR_PROJECT_ID"
                fi
            else
                print_error "GCP not authenticated"
                echo "Please run: gcloud auth login"
                exit 1
            fi
        else
            print_error "Google Cloud CLI not found!"
            echo "Please install gcloud from: https://cloud.google.com/sdk/docs/install"
            exit 1
        fi
        ;;
    azure)
        if command -v az &> /dev/null; then
            print_success "Azure CLI found"
            # Check authentication
            if az account show &> /dev/null; then
                SUBSCRIPTION=$(az account show --query name -o tsv)
                print_success "Azure authenticated (Subscription: $SUBSCRIPTION)"
            else
                print_error "Azure not authenticated"
                echo "Please run: az login"
                exit 1
            fi
        else
            print_error "Azure CLI not found!"
            echo "Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
            exit 1
        fi
        ;;
esac

echo

# Step 4: Configuration
print_step "4. Setting up configuration"

cd "$PROJECT_ROOT/terraform"

TFVARS_FILE="terraform.tfvars"
EXAMPLE_TFVARS="../examples/$CLOUD_PROVIDER/terraform.tfvars"

if [ -f "$TFVARS_FILE" ]; then
    print_warning "Configuration file already exists: $TFVARS_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Keeping existing configuration"
    else
        cp "$EXAMPLE_TFVARS" "$TFVARS_FILE"
        print_success "Configuration updated from example"
    fi
else
    cp "$EXAMPLE_TFVARS" "$TFVARS_FILE"
    print_success "Configuration created from example"
fi

echo

# Step 5: Review configuration
print_step "5. Review your configuration"
echo "Please review and customize the configuration file:"
echo "  📄 File: $PWD/$TFVARS_FILE"
echo

print_warning "Important settings to review:"
case $CLOUD_PROVIDER in
    aws)
        echo "  • region: Your preferred AWS region"
        echo "  • availability_zones: AZs for high availability"
        echo "  • node_instance_type: EC2 instance type for worker nodes"
        ;;
    gcp)
        echo "  • project_id: Your GCP project ID"
        echo "  • region: Your preferred GCP region"
        echo "  • node_machine_type: Compute Engine machine type"
        ;;
    azure)
        echo "  • location: Your preferred Azure region"
        echo "  • node_vm_size: Virtual machine size for nodes"
        ;;
esac
echo

read -p "Press Enter when you've reviewed the configuration..."
echo

# Step 6: Deploy
print_step "6. Ready to deploy!"
echo "This will create:"
echo "  🌐 Virtual Private Cloud (VPC/VNet)"
echo "  ☸️  Kubernetes cluster"
echo "  🗄️  Managed database"
echo "  🔒 Security groups and IAM roles"
echo

print_warning "This will create real cloud resources that may incur costs!"
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled. You can run this script again later."
    echo
    print_status "To deploy manually, run:"
    echo "  cd $PROJECT_ROOT"
    echo "  ./scripts/deploy.sh $CLOUD_PROVIDER $ENVIRONMENT"
    exit 0
fi

# Run deployment
echo
print_step "🚀 Starting deployment..."
if "$SCRIPT_DIR/deploy.sh" "$CLOUD_PROVIDER" "$ENVIRONMENT"; then
    echo
    print_success "🎉 Cheetah deployment completed successfully!"
    echo
    print_status "What's next?"
    echo "  1. 📖 Read the integration guide: $PROJECT_ROOT/docs/integration-guide.md"
    echo "  2. 🚀 Deploy your applications to the cluster"
    echo "  3. ⚙️  Set up CI/CD pipelines"
    echo "  4. 📊 Configure monitoring and alerting"
    echo
    print_status "Useful commands:"
    echo "  • View cluster: kubectl get nodes"
    echo "  • Deploy app: kubectl apply -f your-app.yaml"
    echo "  • Clean up: ./scripts/cleanup.sh $CLOUD_PROVIDER $ENVIRONMENT"
    echo
    print_success "Happy coding! 🐆"
else
    print_error "Deployment failed. Check the logs above for details."
    exit 1
fi
