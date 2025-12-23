#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}

echo "🚀 Full Deployment to AWS"
echo "Environment: $ENVIRONMENT"
echo "=========================="
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

AWS_ACCOUNT_ID=199299155478
AWS_REGION=${AWS_REGION:-us-east-1}

echo "📊 Deployment Info:"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo "  Environment: $ENVIRONMENT"
echo ""

# Step 1: Initialize Terraform Backend
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/6: Initialize Terraform Backend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BUCKET_NAME="tfstate-${AWS_ACCOUNT_ID}-${ENVIRONMENT}"
TABLE_NAME="tfstate-lock-${ENVIRONMENT}"

# Create S3 bucket for Terraform state
if ! aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "📦 Creating S3 bucket: ${BUCKET_NAME}"
    aws s3 mb "s3://${BUCKET_NAME}" --region ${AWS_REGION}
    
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
    
    echo "✅ S3 bucket created"
else
    echo "✅ S3 bucket already exists"
fi

# Create DynamoDB table for state locking
if ! aws dynamodb describe-table --table-name ${TABLE_NAME} --region ${AWS_REGION} 2>/dev/null; then
    echo "🔒 Creating DynamoDB table: ${TABLE_NAME}"
    aws dynamodb create-table \
        --table-name ${TABLE_NAME} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ${AWS_REGION}
    
    echo "⏳ Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name ${TABLE_NAME} --region ${AWS_REGION}
    echo "✅ DynamoDB table created"
else
    echo "✅ DynamoDB table already exists"
fi

# Step 2: Deploy Infrastructure with Terraform
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/6: Deploy Infrastructure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd terraform

# Initialize Terraform
echo "⚙️  Initializing Terraform..."
terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
    -backend-config="dynamodb_table=${TABLE_NAME}" \
    -backend-config="region=${AWS_REGION}"

# Validate
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan
echo "📋 Creating Terraform plan..."
terraform plan \
    -var="environment=${ENVIRONMENT}" \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    -out=tfplan

# Apply
echo ""
echo "🔨 Applying Terraform changes..."
echo "⚠️  This will create AWS resources (may incur costs)"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

terraform apply tfplan

# Get outputs
echo ""
echo "📊 Terraform Outputs:"
terraform output

# Save important outputs
ECR_REPOSITORY=$(terraform output -raw ecr_repository_url)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ALB_DNS=$(terraform output -raw alb_dns_name)
CLOUDFRONT_DIST_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

cd ..

# Update .env with outputs
echo "📝 Updating .env with infrastructure outputs..."
sed -i.bak "s|ECR_REPOSITORY=.*|ECR_REPOSITORY=${ECR_REPOSITORY}|g" .env
sed -i.bak "s|ECS_CLUSTER=.*|ECS_CLUSTER=${ECS_CLUSTER}|g" .env
sed -i.bak "s|ALB_DNS=.*|ALB_DNS=${ALB_DNS}|g" .env
if [ -n "$CLOUDFRONT_DIST_ID" ]; then
    sed -i.bak "s|CLOUDFRONT_DISTRIBUTION_ID=.*|CLOUDFRONT_DISTRIBUTION_ID=${CLOUDFRONT_DIST_ID}|g" .env
fi

# Step 3: Build Application
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/6: Build Application"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📦 Building with Maven..."
./mvnw clean package -DskipTests -Dspring-boot.run.profiles=aws

# Step 4: Build and Push Docker Image
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4/6: Build and Push Docker Image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_TAG="${GIT_SHA}-$(date +%Y%m%d-%H%M%S)"

echo "🐳 Building Docker image for AMD64 (AWS)..."
podman build \
    --platform linux/amd64 \
    --format docker \
    --build-arg SPRING_PROFILES_ACTIVE=aws \
    --tag my-java-backend:${IMAGE_TAG} \
    --tag my-java-backend:latest \
    .

echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    podman login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "🏷️  Tagging images..."
podman tag my-java-backend:${IMAGE_TAG} ${ECR_REPOSITORY}:${IMAGE_TAG}
podman tag my-java-backend:latest ${ECR_REPOSITORY}:latest

echo "⬆️  Pushing to ECR..."
podman push ${ECR_REPOSITORY}:${IMAGE_TAG}
podman push ${ECR_REPOSITORY}:latest

# Step 5: Deploy to ECS
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5/6: Deploy to ECS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SERVICE_NAME="my-java-backend-service-${ENVIRONMENT}"

# Force new deployment with new image
echo "🔄 Updating ECS service..."

aws ecs update-service \
    --cluster ${ECS_CLUSTER} \
    --service ${SERVICE_NAME} \
    --force-new-deployment \
    --region ${AWS_REGION} \
    > /dev/null

echo "⏳ Waiting for service to stabilize (this may take a few minutes)..."
aws ecs wait services-stable \
    --cluster ${ECS_CLUSTER} \
    --services ${SERVICE_NAME} \
    --region ${AWS_REGION}

echo "✅ ECS service updated successfully"

# Step 6: Verify Deployment
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6/6: Verify Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check running tasks
echo "📊 Running tasks:"
aws ecs list-tasks \
    --cluster ${ECS_CLUSTER} \
    --service-name ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    --query 'taskArns[]' \
    --output table

# Get task details
TASK_ARN=$(aws ecs list-tasks \
    --cluster ${ECS_CLUSTER} \
    --service-name ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    --query 'taskArns[0]' \
    --output text)

if [ -n "$TASK_ARN" ] && [ "$TASK_ARN" != "None" ]; then
    echo ""
    echo "📋 Task details:"
    aws ecs describe-tasks \
        --cluster ${ECS_CLUSTER} \
        --tasks ${TASK_ARN} \
        --region ${AWS_REGION} \
        --query 'tasks[0].[taskArn,lastStatus,healthStatus,containers[0].lastStatus]' \
        --output table
fi

# Health check
echo ""
echo "🏥 Health check:"
sleep 10  # Wait for application to start

if curl -sf "http://${ALB_DNS}/health" > /dev/null 2>&1; then
    echo "✅ Application is healthy!"
    curl -s "http://${ALB_DNS}/health" | jq . || curl -s "http://${ALB_DNS}/health"
else
    echo "⚠️  Health check failed - application may still be starting"
    echo "   Check logs: aws logs tail /ecs/my-java-backend-${ENVIRONMENT} --follow"
fi

# Invalidate CloudFront cache if exists
if [ -n "$CLOUDFRONT_DIST_ID" ]; then
    echo ""
    echo "🗑️  Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id ${CLOUDFRONT_DIST_ID} \
        --paths "/*" \
        --region ${AWS_REGION} \
        > /dev/null
    echo "✅ CloudFront cache invalidated"
fi

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Deployment Summary:"
echo "  Environment: ${ENVIRONMENT}"
echo "  Region: ${AWS_REGION}"
echo "  Image: ${ECR_REPOSITORY}:${IMAGE_TAG}"
echo "  ECS Cluster: ${ECS_CLUSTER}"
echo "  ALB URL: http://${ALB_DNS}"
if [ -n "$CLOUDFRONT_DIST_ID" ]; then
    CLOUDFRONT_DNS=$(aws cloudfront get-distribution --id ${CLOUDFRONT_DIST_ID} --query 'Distribution.DomainName' --output text)
    echo "  CloudFront: https://${CLOUDFRONT_DNS}"
fi
echo ""
echo "🔗 Useful commands:"
echo "  View logs:       aws logs tail /ecs/my-java-backend-${ENVIRONMENT} --follow"
echo "  Service status:  aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${SERVICE_NAME} --region ${AWS_REGION}"
echo "  Scale service:   aws ecs update-service --cluster ${ECS_CLUSTER} --service ${SERVICE_NAME} --desired-count 3"
echo ""
