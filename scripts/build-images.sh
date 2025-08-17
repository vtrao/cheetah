#!/bin/bash

# Cheetah Docker Build Script
# Builds multi-architecture Docker images and pushes to registry
# Usage: ./build-images.sh [project_name] [environment] [cloud_provider]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[CHEETAH-BUILD]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[CHEETAH-BUILD]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[CHEETAH-BUILD]${NC} $1"
}

print_error() {
    echo -e "${RED}[CHEETAH-BUILD]${NC} $1"
}

# Parameters
PROJECT_NAME=${1:-proj}
ENVIRONMENT=${2:-dev}
CLOUD_PROVIDER=${3:-aws}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEETAH_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CHEETAH_ROOT")"

print_status "🏗️  Building Docker images for project: $PROJECT_NAME"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

# Determine target platform (use linux/amd64 for cloud deployments)
TARGET_PLATFORM="linux/amd64"
if [ "$ENVIRONMENT" = "local" ]; then
    TARGET_PLATFORM="linux/$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')"
fi

print_status "Target Platform: $TARGET_PLATFORM"

# Get container registry
CONTAINER_REGISTRY=""
case $CLOUD_PROVIDER in
    aws)
        if command -v aws &> /dev/null; then
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
            REGION=$(aws configure get region || echo "us-east-1")
            if [ -n "$ACCOUNT_ID" ]; then
                CONTAINER_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
                
                # Authenticate with ECR
                print_status "🔐 Authenticating with ECR..."
                aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$CONTAINER_REGISTRY" || {
                    print_error "ECR authentication failed"
                    exit 1
                }
                print_success "✅ ECR authentication successful"
                
                # Create repositories if they don't exist
                for repo in backend frontend; do
                    print_status "Creating ECR repository: $PROJECT_NAME/$repo"
                    aws ecr create-repository --repository-name "$PROJECT_NAME/$repo" --region "$REGION" 2>/dev/null || print_warning "Repository may already exist"
                done
            fi
        fi
        ;;
    gcp)
        # Add GCP authentication logic
        CONTAINER_REGISTRY="gcr.io/PROJECT_ID"
        ;;
    azure)
        # Add Azure authentication logic
        CONTAINER_REGISTRY="REGISTRY_NAME.azurecr.io"
        ;;
esac

if [ -z "$CONTAINER_REGISTRY" ]; then
    print_warning "Using local registry (localhost:5000)"
    CONTAINER_REGISTRY="localhost:5000"
fi

print_status "Container Registry: $CONTAINER_REGISTRY"

# Build function
build_and_push() {
    local service=$1
    local service_dir="$PROJECT_ROOT/$service"
    local image_name="$CONTAINER_REGISTRY/$PROJECT_NAME/$service:latest"
    local tag_with_env="$CONTAINER_REGISTRY/$PROJECT_NAME/$service:$ENVIRONMENT"
    
    if [ ! -d "$service_dir" ]; then
        print_warning "⚠️  $service directory not found at $service_dir, skipping..."
        return 0
    fi
    
    if [ ! -f "$service_dir/Dockerfile" ]; then
        print_warning "⚠️  Dockerfile not found in $service_dir, skipping..."
        return 0
    fi
    
    print_status "🐳 Building $service image..."
    
    # Build with buildx for multi-platform support
    if docker buildx version >/dev/null 2>&1; then
        print_status "Using Docker Buildx for $service..."
        
        # Create builder if it doesn't exist
        docker buildx create --name cheetah-builder --use 2>/dev/null || docker buildx use cheetah-builder 2>/dev/null || true
        
        # Build and push in one step
        docker buildx build \
            --platform "$TARGET_PLATFORM" \
            --push \
            --tag "$image_name" \
            --tag "$tag_with_env" \
            "$service_dir"
    else
        print_status "Using regular Docker build for $service..."
        
        # Regular build
        docker build \
            --platform "$TARGET_PLATFORM" \
            --tag "$image_name" \
            --tag "$tag_with_env" \
            "$service_dir"
        
        # Push both tags
        docker push "$image_name"
        docker push "$tag_with_env"
    fi
    
    print_success "✅ $service image built and pushed successfully"
    
    # Show image info
    docker images --filter reference="$CONTAINER_REGISTRY/$PROJECT_NAME/$service" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Build services
SERVICES=("backend" "frontend")

for service in "${SERVICES[@]}"; do
    build_and_push "$service"
done

# Verify images
print_status "🔍 Verifying pushed images..."
for service in "${SERVICES[@]}"; do
    image_name="$CONTAINER_REGISTRY/$PROJECT_NAME/$service:latest"
    
    case $CLOUD_PROVIDER in
        aws)
            if command -v aws &> /dev/null && [ "$CONTAINER_REGISTRY" != "localhost:5000" ]; then
                print_status "Checking $service in ECR..."
                aws ecr describe-images --repository-name "$PROJECT_NAME/$service" --region "$REGION" --query 'imageDetails[0].imageTags' 2>/dev/null || print_warning "Could not verify $service image"
            fi
            ;;
    esac
done

print_success "🎉 Docker image build completed!"
print_status ""
print_status "Built images:"
for service in "${SERVICES[@]}"; do
    echo "  📦 $CONTAINER_REGISTRY/$PROJECT_NAME/$service:latest"
    echo "  📦 $CONTAINER_REGISTRY/$PROJECT_NAME/$service:$ENVIRONMENT"
done
print_status ""
print_status "Next: Run deployment with ./deploy-apps.sh"
