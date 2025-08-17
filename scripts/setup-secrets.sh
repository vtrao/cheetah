#!/bin/bash
# Cloud-agnostic secrets management script for Cheetah platform

set -e

CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-dev}
PROJECT_NAME=${3:-cheetah}

echo "🔐 Setting up secrets for $CLOUD_PROVIDER in $ENVIRONMENT environment..."

case $CLOUD_PROVIDER in
  "aws")
    echo "Using AWS Secrets Manager and Parameter Store..."
    # Create secrets in AWS Systems Manager Parameter Store
    aws ssm put-parameter \
      --name "/$PROJECT_NAME/$ENVIRONMENT/database/password" \
      --value "$(openssl rand -base64 32)" \
      --type "SecureString" \
      --overwrite
    
    aws ssm put-parameter \
      --name "/$PROJECT_NAME/$ENVIRONMENT/app/secret-key" \
      --value "$(openssl rand -base64 64)" \
      --type "SecureString" \
      --overwrite
    ;;
    
  "gcp")
    echo "Using GCP Secret Manager..."
    # Create secrets in GCP Secret Manager
    echo -n "$(openssl rand -base64 32)" | gcloud secrets create ${PROJECT_NAME}-${ENVIRONMENT}-db-password --data-file=-
    echo -n "$(openssl rand -base64 64)" | gcloud secrets create ${PROJECT_NAME}-${ENVIRONMENT}-app-secret --data-file=-
    ;;
    
  "azure")
    echo "Using Azure Key Vault..."
    # Create secrets in Azure Key Vault
    az keyvault secret set \
      --vault-name "${PROJECT_NAME}-${ENVIRONMENT}-kv" \
      --name "database-password" \
      --value "$(openssl rand -base64 32)"
    
    az keyvault secret set \
      --vault-name "${PROJECT_NAME}-${ENVIRONMENT}-kv" \
      --name "app-secret-key" \
      --value "$(openssl rand -base64 64)"
    ;;
    
  *)
    echo "❌ Unsupported cloud provider: $CLOUD_PROVIDER"
    exit 1
    ;;
esac

# Create Kubernetes secret for external-secrets operator
kubectl create secret generic cloud-credentials \
  --from-literal=cloud-provider=$CLOUD_PROVIDER \
  --namespace=cheetah-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply external-secrets configuration if it exists
if [ -d "../kubernetes/external-secrets" ]; then
    kubectl apply -f ../kubernetes/external-secrets/
elif [ -d "../k8s/external-secrets" ]; then
    kubectl apply -f ../k8s/external-secrets/
else
    echo "⚠️  External secrets configuration not found"
fi

echo "✅ Secrets setup completed for $CLOUD_PROVIDER"
echo "🔐 Secrets are now managed securely using $CLOUD_PROVIDER native secret stores"
echo "📋 Next steps:"
echo "   1. Verify secrets in cloud console"
echo "   2. Test Terraform deployment with data sources"
echo "   3. Deploy External Secrets Operator to Kubernetes"
