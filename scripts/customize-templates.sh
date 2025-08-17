#!/bin/bash

# Cheetah Template Customization Script
# This script customizes Kubernetes templates for a specific project
# Usage: ./customize-templates.sh [project_name] [environment] [cloud_provider]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[CHEETAH-CUSTOMIZE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[CHEETAH-CUSTOMIZE]${NC} $1"
}

print_error() {
    echo -e "${RED}[CHEETAH-CUSTOMIZE]${NC} $1"
}

# Parameters
PROJECT_NAME=${1:-proj}
ENVIRONMENT=${2:-dev}
CLOUD_PROVIDER=${3:-aws}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEETAH_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CHEETAH_ROOT")"

print_status "🎨 Customizing Kubernetes templates for project: $PROJECT_NAME"

# Create target directory
TARGET_DIR="$PROJECT_ROOT/kubernetes"
mkdir -p "$TARGET_DIR"

# Template directory
TEMPLATE_DIR="$CHEETAH_ROOT/kubernetes/templates"

if [ ! -d "$TEMPLATE_DIR" ]; then
    print_error "Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Get container registry based on cloud provider
CONTAINER_REGISTRY=""
case $CLOUD_PROVIDER in
    aws)
        if command -v aws &> /dev/null; then
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
            REGION=$(aws configure get region || echo "us-east-1")
            if [ -n "$ACCOUNT_ID" ]; then
                CONTAINER_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
            fi
        fi
        ;;
    gcp)
        # Add GCP container registry logic
        CONTAINER_REGISTRY="gcr.io/PROJECT_ID"
        ;;
    azure)
        # Add Azure container registry logic
        CONTAINER_REGISTRY="REGISTRY_NAME.azurecr.io"
        ;;
esac

if [ -z "$CONTAINER_REGISTRY" ]; then
    print_error "Could not determine container registry for $CLOUD_PROVIDER"
    CONTAINER_REGISTRY="localhost:5000"  # Fallback for local development
fi

print_status "Container Registry: $CONTAINER_REGISTRY"

# Get RDS endpoint if available
RDS_ENDPOINT=""
if [ "$CLOUD_PROVIDER" = "aws" ] && command -v aws &> /dev/null; then
    RDS_ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "${PROJECT_NAME}-${ENVIRONMENT}-db" \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text 2>/dev/null || echo "")
fi

if [ -z "$RDS_ENDPOINT" ] || [ "$RDS_ENDPOINT" = "None" ]; then
    RDS_ENDPOINT="database-service.${PROJECT_NAME}-app.svc.cluster.local"
    print_status "Using cluster-local database service"
else
    print_status "Using RDS endpoint: $RDS_ENDPOINT"
fi

# Customize each template
for template in "$TEMPLATE_DIR"/*.yaml; do
    if [ -f "$template" ]; then
        filename=$(basename "$template")
        target_file="$TARGET_DIR/$filename"
        
        print_status "Customizing $filename..."
        
        # Replace placeholders
        sed -e "s/PROJECT_NAME/$PROJECT_NAME/g" \
            -e "s/ENVIRONMENT/$ENVIRONMENT/g" \
            -e "s|CONTAINER_REGISTRY|$CONTAINER_REGISTRY|g" \
            -e "s/RDS_ENDPOINT/$RDS_ENDPOINT/g" \
            "$template" > "$target_file"
        
        print_success "✅ Created $target_file"
    fi
done

# Create directory structure
mkdir -p "$TARGET_DIR/backend" "$TARGET_DIR/frontend" "$TARGET_DIR/database"

# Move files to appropriate directories
if [ -f "$TARGET_DIR/namespace-and-secrets.yaml" ]; then
    mv "$TARGET_DIR/namespace-and-secrets.yaml" "$TARGET_DIR/namespace.yaml"
fi

if [ -f "$TARGET_DIR/backend-deployment.yaml" ]; then
    mv "$TARGET_DIR/backend-deployment.yaml" "$TARGET_DIR/backend/deployment.yaml"
fi

if [ -f "$TARGET_DIR/frontend-deployment.yaml" ]; then
    mv "$TARGET_DIR/frontend-deployment.yaml" "$TARGET_DIR/frontend/deployment.yaml"
fi

if [ -f "$TARGET_DIR/database-service.yaml" ]; then
    mv "$TARGET_DIR/database-service.yaml" "$TARGET_DIR/database/service.yaml"
fi

# Create ingress template
cat > "$TARGET_DIR/ingress.yaml" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${PROJECT_NAME}-app-ingress
  namespace: ${PROJECT_NAME}-app
  annotations:
    # Add ingress controller specific annotations
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
  labels:
    app: ${PROJECT_NAME}-app
    environment: ${ENVIRONMENT}
    managed-by: cheetah
spec:
  rules:
  - host: ${PROJECT_NAME}-app.local
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8000
      - path: /()(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF

print_success "✅ Created ingress configuration"

# Generate secrets with random password
if command -v openssl &> /dev/null; then
    RANDOM_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    ENCODED_PASSWORD=$(echo -n "$RANDOM_PASSWORD" | base64)
    
    # Update the secret in namespace.yaml
    sed -i.bak "s/Q2hhbmdlTWUxMjM=/$ENCODED_PASSWORD/" "$TARGET_DIR/namespace.yaml" && rm "$TARGET_DIR/namespace.yaml.bak"
    
    print_status "Generated secure random database password"
    print_status "Password (save this): $RANDOM_PASSWORD"
fi

print_success "🎉 Template customization completed!"
print_status "Customized manifests are in: $TARGET_DIR"
print_status ""
print_status "Next steps:"
echo "  1. Review the generated manifests"
echo "  2. Update any project-specific configurations"
echo "  3. Run: ./deploy-apps.sh $ENVIRONMENT $CLOUD_PROVIDER $PROJECT_NAME"
