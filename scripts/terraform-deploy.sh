#!/bin/bash

set -e

ENVIRONMENT=${1:-production}
ACTION=${2:-apply}

echo "🚀 Terraform $ACTION for $ENVIRONMENT..."

cd terraform

# Validate
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan
echo "📋 Creating Terraform plan..."
terraform plan \
    -var="environment=${ENVIRONMENT}" \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    -out=tfplan

if [ "$ACTION" == "plan" ]; then
    echo "✅ Plan created. Review tfplan file."
    exit 0
fi

# Apply
echo "🔨 Applying Terraform changes..."
read -p "Do you want to apply these changes? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

terraform apply tfplan

# Show outputs
echo ""
echo "📊 Deployment Outputs:"
terraform output

echo ""
echo "✅ Infrastructure deployed successfully!"