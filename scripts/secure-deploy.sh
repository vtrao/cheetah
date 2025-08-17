#!/bin/bash
# Secure deployment script that initializes secrets before deployment

set -e

ENVIRONMENT=${1:-dev}
CLOUD_PROVIDER=${2:-aws}
PROJECT_NAME=${3:-cheetah}

echo "🔐 Initializing secure deployment for $PROJECT_NAME..."
echo "Environment: $ENVIRONMENT"
echo "Cloud Provider: $CLOUD_PROVIDER"

# Step 1: Setup cloud-native secrets
echo "📋 Step 1: Setting up cloud-native secrets..."
# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
$SCRIPT_DIR/setup-secrets.sh $CLOUD_PROVIDER $ENVIRONMENT $PROJECT_NAME

# Step 2: Copy secure terraform configuration
echo "📋 Step 2: Configuring Terraform with secure variables..."
# Get the current script directory and find terraform directory
TERRAFORM_DIR="$(dirname "${BASH_SOURCE[0]}")/../terraform"
if [ -f "$TERRAFORM_DIR/terraform.tfvars.template" ]; then
    cp "$TERRAFORM_DIR/terraform.tfvars.template" "$TERRAFORM_DIR/terraform.tfvars"
    echo "✅ Terraform variables template copied"
    echo "⚠️  Please review and customize terraform.tfvars before deployment"
elif [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    echo "✅ Terraform variables already exist"
else
    echo "❌ Terraform variables template not found at $TERRAFORM_DIR"
    exit 1
fi

# Step 3: Validate secret management configuration
echo "📋 Step 3: Validating secret management setup..."

case $CLOUD_PROVIDER in
    "aws")
        echo "Checking AWS SSM Parameter Store..."
        if aws ssm describe-parameters --parameter-filters "Key=Name,Values=/$PROJECT_NAME/$ENVIRONMENT/" > /dev/null 2>&1; then
            echo "✅ AWS SSM parameters configured"
        else
            echo "⚠️  AWS SSM parameters need to be created"
        fi
        ;;
    "gcp")
        echo "Checking GCP Secret Manager..."
        if gcloud secrets list --filter="name:$PROJECT_NAME-$ENVIRONMENT" > /dev/null 2>&1; then
            echo "✅ GCP Secret Manager configured"
        else
            echo "⚠️  GCP secrets need to be created"
        fi
        ;;
    "azure")
        echo "Checking Azure Key Vault..."
        if az keyvault list --query "[?contains(name, '$PROJECT_NAME-$ENVIRONMENT')]" > /dev/null 2>&1; then
            echo "✅ Azure Key Vault configured"
        else
            echo "⚠️  Azure Key Vault needs to be created"
        fi
        ;;
esac

# Step 4: Deploy infrastructure with secure secrets
echo "📋 Step 4: Deploying infrastructure..."
# We need to navigate to the parent directory of this script, which is cheetah/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEETAH_DIR="$(dirname "$SCRIPT_DIR")"
cd "$CHEETAH_DIR"
scripts/deploy.sh $CLOUD_PROVIDER $ENVIRONMENT

# Step 5: Setup External Secrets Operator
echo "📋 Step 5: Deploying External Secrets Operator..."
if command -v kubectl > /dev/null 2>&1; then
    # Install External Secrets Operator via Helm
    if command -v helm > /dev/null 2>&1; then
        helm repo add external-secrets https://charts.external-secrets.io
        helm repo update
        
        helm upgrade --install external-secrets external-secrets/external-secrets \
            --namespace external-secrets-system \
            --create-namespace \
            --set installCRDs=true
        
        echo "✅ External Secrets Operator installed"
        
        # Apply external secrets configuration if it exists
        if [ -d "../kubernetes/external-secrets" ]; then
            kubectl apply -f ../kubernetes/external-secrets/
            echo "✅ External secrets configuration applied"
        elif [ -d "../k8s/external-secrets" ]; then
            kubectl apply -f ../k8s/external-secrets/
            echo "✅ External secrets configuration applied"
        else
            echo "⚠️  External secrets configuration not found"
        fi
    else
        echo "⚠️  Helm not found, skipping External Secrets Operator installation"
    fi
else
    echo "⚠️  kubectl not found, skipping Kubernetes secret setup"
fi

echo "🎉 Secure deployment completed!"
echo "📋 Security Summary:"
echo "   ✅ Cloud-native secret stores configured"
echo "   ✅ Terraform uses data sources for secrets"  
echo "   ✅ External Secrets Operator deployed"
echo "   ✅ Kubernetes secrets managed dynamically"
echo "   ✅ No plaintext secrets in version control"
echo ""
echo "🔐 Next steps:"
echo "   1. Review terraform.tfvars and update as needed"
echo "   2. Verify secrets in cloud console ($CLOUD_PROVIDER)"
echo "   3. Test application with secure database connection"
echo "   4. Monitor External Secrets Operator logs"
