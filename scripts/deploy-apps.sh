#!/bin/bash

# Cheetah Application Deployment Script for Kubernetes
# This script deploys applications after infrastructure is ready with comprehensive error handling
# Usage: ./deploy-apps.sh [environment] [cloud_provider] [project_name]

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
    echo -e "${BLUE}[CHEETAH-APPS]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[CHEETAH-APPS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[CHEETAH-APPS]${NC} $1"
}

print_error() {
    echo -e "${RED}[CHEETAH-APPS]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[CHEETAH-APPS]${NC} $1"
}

# Default values
ENVIRONMENT=${1:-dev}
CLOUD_PROVIDER=${2:-aws}
PROJECT_NAME=${3:-proj}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEETAH_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CHEETAH_ROOT")"

print_status "🚀 Cheetah Application Deployment Starting..."
print_status "Environment: $ENVIRONMENT"
print_status "Cloud Provider: $CLOUD_PROVIDER"
print_status "Project Name: $PROJECT_NAME"
print_status "Project Root: $PROJECT_ROOT"

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod"
    exit 1
fi

if [[ ! "$CLOUD_PROVIDER" =~ ^(aws|gcp|azure)$ ]]; then
    print_error "Invalid cloud provider: $CLOUD_PROVIDER. Must be aws, gcp, or azure"
    exit 1
fi

# Check dependencies
print_status "🔍 Checking dependencies..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "docker is not installed. Please install Docker first."
    exit 1
fi

print_success "✅ All dependencies available"

# Set up kubeconfig
print_status "🔧 Setting up Kubernetes configuration..."

# Try multiple kubeconfig locations
KUBECONFIG_LOCATIONS=(
    "$CHEETAH_ROOT/terraform/kubeconfig-$CLOUD_PROVIDER-$ENVIRONMENT.yaml"
    "$PROJECT_ROOT/terraform/kubeconfig-$CLOUD_PROVIDER-$ENVIRONMENT.yaml"
    "$PROJECT_ROOT/kubeconfig"
    "$HOME/.kube/config"
)

KUBECONFIG_FILE=""
for config in "${KUBECONFIG_LOCATIONS[@]}"; do
    if [ -f "$config" ]; then
        KUBECONFIG_FILE="$config"
        break
    fi
done

if [ -z "$KUBECONFIG_FILE" ]; then
    print_error "No kubeconfig found. Tried:"
    for config in "${KUBECONFIG_LOCATIONS[@]}"; do
        echo "  - $config"
    done
    print_error "Please run infrastructure deployment first or configure kubectl manually"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_FILE"
print_success "Using kubeconfig: $KUBECONFIG_FILE"

# Update kubeconfig for cloud provider
case $CLOUD_PROVIDER in
    aws)
        print_status "Updating AWS EKS kubeconfig..."
        if command -v aws &> /dev/null; then
            CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
            REGION=$(aws configure get region || echo "us-east-1")
            aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || print_warning "Failed to update EKS kubeconfig, using existing"
        fi
        ;;
    gcp)
        print_status "Updating GCP GKE kubeconfig..."
        # Add GKE kubeconfig update logic
        ;;
    azure)
        print_status "Updating Azure AKS kubeconfig..."
        # Add AKS kubeconfig update logic
        ;;
esac

# Verify cluster connectivity
print_status "🔗 Verifying cluster connectivity..."
if ! kubectl cluster-info > /dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster"
    print_error "Please ensure the cluster is running and kubeconfig is correct"
    print_info "Cluster info:"
    kubectl cluster-info || true
    exit 1
fi

CLUSTER_INFO=$(kubectl cluster-info --short 2>/dev/null | head -1)
print_success "✅ Connected to cluster: $CLUSTER_INFO"

# Get cluster nodes info
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
print_info "📊 Cluster has $NODE_COUNT nodes"

# Check if ECR/container registry authentication is needed
print_status "🔐 Checking container registry authentication..."

case $CLOUD_PROVIDER in
    aws)
        if command -v aws &> /dev/null; then
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
            if [ -n "$ACCOUNT_ID" ]; then
                REGION=$(aws configure get region || echo "us-east-1")
                ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
                print_info "ECR Registry: $ECR_REGISTRY"
                
                # Authenticate with ECR
                print_status "Authenticating with ECR..."
                aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY" || print_warning "ECR authentication failed"
            fi
        fi
        ;;
esac

# Ensure Docker images are built and pushed
print_status "🏗️  Checking Docker images..."

BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

if [ -d "$BACKEND_DIR" ] && [ -f "$BACKEND_DIR/Dockerfile" ]; then
    print_status "Building backend image for linux/amd64..."
    (
        cd "$BACKEND_DIR"
        if [ -n "$ECR_REGISTRY" ]; then
            docker build --platform linux/amd64 -t "$ECR_REGISTRY/$PROJECT_NAME/backend:latest" .
            docker push "$ECR_REGISTRY/$PROJECT_NAME/backend:latest" || print_warning "Backend push failed"
        else
            docker build -t "$PROJECT_NAME/backend:latest" .
        fi
    )
    print_success "✅ Backend image ready"
fi

if [ -d "$FRONTEND_DIR" ] && [ -f "$FRONTEND_DIR/Dockerfile" ]; then
    print_status "Building frontend image for linux/amd64..."
    (
        cd "$FRONTEND_DIR"
        if [ -n "$ECR_REGISTRY" ]; then
            docker build --platform linux/amd64 -t "$ECR_REGISTRY/$PROJECT_NAME/frontend:latest" .
            docker push "$ECR_REGISTRY/$PROJECT_NAME/frontend:latest" || print_warning "Frontend push failed"
        else
            docker build -t "$PROJECT_NAME/frontend:latest" .
        fi
    )
    print_success "✅ Frontend image ready"
fi

# Deploy applications
print_status "📦 Deploying application manifests..."

# Define deployment order
DEPLOY_ORDER=(
    "kubernetes/namespace.yaml"
    "kubernetes/database/"
    "kubernetes/backend/"
    "kubernetes/frontend/"
    "kubernetes/ingress.yaml"
)

# Find kubernetes manifests directory
KUBE_DIR=""
if [ -d "$PROJECT_ROOT/infrastructure/kubernetes" ]; then
    KUBE_DIR="$PROJECT_ROOT/infrastructure/kubernetes"
elif [ -d "$PROJECT_ROOT/kubernetes" ]; then
    KUBE_DIR="$PROJECT_ROOT/kubernetes"
elif [ -d "$PROJECT_ROOT/k8s" ]; then
    KUBE_DIR="$PROJECT_ROOT/k8s"
fi

if [ -z "$KUBE_DIR" ]; then
    print_error "No kubernetes manifests directory found"
    exit 1
fi

print_info "Using manifests from: $KUBE_DIR"

for manifest in "${DEPLOY_ORDER[@]}"; do
    MANIFEST_PATH="$KUBE_DIR/$manifest"
    
    if [ -f "$MANIFEST_PATH" ] || [ -d "$MANIFEST_PATH" ]; then
        print_status "Applying $manifest..."
        if kubectl apply -f "$MANIFEST_PATH" --validate=false; then
            print_success "✅ Applied $manifest"
        else
            print_error "❌ Failed to apply $manifest"
            # Continue with other manifests instead of exiting
            continue
        fi
    else
        print_warning "⚠️  $manifest not found at $MANIFEST_PATH, skipping..."
    fi
done

# Initialize database if needed
print_status "🗄️  Checking database initialization..."

DB_INIT_JOB="$KUBE_DIR/database-init-job.yaml"
if [ -f "$DB_INIT_JOB" ]; then
    print_status "Running database initialization job..."
    kubectl delete job database-init -n ${PROJECT_NAME}-app --ignore-not-found=true
    kubectl apply -f "$DB_INIT_JOB" --validate=false
    
    # Wait for job completion
    print_status "Waiting for database initialization..."
    if kubectl wait --for=condition=complete job/database-init -n ${PROJECT_NAME}-app --timeout=120s; then
        print_success "✅ Database initialized successfully"
        kubectl logs job/database-init -n ${PROJECT_NAME}-app
    else
        print_warning "⚠️  Database initialization job timed out or failed"
        kubectl describe job database-init -n ${PROJECT_NAME}-app || true
    fi
fi

# Wait for deployments to be ready
print_status "⏳ Waiting for deployments to be ready..."

NAMESPACE="${PROJECT_NAME}-app"

# Function to wait for deployment
wait_for_deployment() {
    local deployment=$1
    if kubectl get deployment "$deployment" -n "$NAMESPACE" > /dev/null 2>&1; then
        print_status "Waiting for $deployment deployment..."
        if kubectl rollout status deployment/"$deployment" -n "$NAMESPACE" --timeout=300s; then
            print_success "✅ $deployment deployment ready"
            return 0
        else
            print_error "❌ $deployment deployment failed to become ready"
            kubectl describe deployment "$deployment" -n "$NAMESPACE" || true
            kubectl get pods -l app="$deployment" -n "$NAMESPACE" || true
            return 1
        fi
    else
        print_warning "⚠️  $deployment deployment not found, skipping..."
        return 0
    fi
}

# Wait for each deployment
wait_for_deployment "backend"
wait_for_deployment "frontend"

# Show comprehensive status
print_status "📊 Deployment Status Summary:"
echo
print_info "=== PODS ==="
kubectl get pods -n "$NAMESPACE" -o wide || true
echo
print_info "=== SERVICES ==="
kubectl get services -n "$NAMESPACE" || true
echo
print_info "=== INGRESS ==="
kubectl get ingress -n "$NAMESPACE" || true
echo
print_info "=== SECRETS ==="
kubectl get secrets -n "$NAMESPACE" || true
echo

# Health check
print_status "🏥 Running health checks..."

# Check if backend is healthy
if kubectl get deployment backend -n "$NAMESPACE" > /dev/null 2>&1; then
    BACKEND_PODS=$(kubectl get pods -l app=backend -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$BACKEND_PODS" -gt 0 ]; then
        BACKEND_POD=$(kubectl get pods -l app=backend -n "$NAMESPACE" --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$BACKEND_POD" ]; then
            print_status "Testing backend health endpoint..."
            if kubectl exec "$BACKEND_POD" -n "$NAMESPACE" -- curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
                print_success "✅ Backend health check passed"
            else
                print_warning "⚠️  Backend health check failed"
            fi
        fi
    fi
fi

# Final success message
print_success "🎉 Cheetah Application Deployment Completed!"
print_status ""
print_status "Next Steps:"
echo "  📋 Check logs: kubectl logs -f deployment/backend -n $NAMESPACE"
echo "  🔌 Port forward: kubectl port-forward svc/frontend-service 8080:80 -n $NAMESPACE"
echo "  🌐 Access app: http://localhost:8080"
echo "  📊 Monitor: kubectl get pods -n $NAMESPACE -w"
echo ""
print_info "Happy coding with Cheetah! 🐆"
