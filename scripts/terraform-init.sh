#!/bin/bash

set -e

ENVIRONMENT=${1:-production}

echo "🔧 Initializing Terraform for $ENVIRONMENT..."

cd terraform

# Create backend bucket if it doesn't exist
BUCKET_NAME="my-terraform-state-${ENVIRONMENT}"
if ! aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "📦 Creating S3 bucket for Terraform state..."
    aws s3 mb "s3://${BUCKET_NAME}" --region us-east-1
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
fi

# Create DynamoDB table for state locking
TABLE_NAME="terraform-lock-${ENVIRONMENT}"
if ! aws dynamodb describe-table --table-name ${TABLE_NAME} 2>/dev/null; then
    echo "🔒 Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name ${TABLE_NAME} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region us-east-1
fi

# Initialize Terraform
echo "⚙️  Initializing Terraform..."
terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="key=java-backend/terraform.tfstate" \
    -backend-config="dynamodb_table=${TABLE_NAME}" \
    -backend-config="region=us-east-1"

echo "✅ Terraform initialized successfully!"