#!/bin/bash

set -e

VM_NAME="podman-machine-default"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-java-backend"
GIT_SHA=$(git rev-parse --short HEAD)
IMAGE_TAG="${GIT_SHA}-$(date +%Y%m%d-%H%M%S)"
ARCH=$(uname -m)

echo "🚀 Deploying to AWS with AWS profile..."
echo "📊 Architecture: $ARCH"
echo "🏷️  Spring Profile: aws"
echo "🌐 Region: $AWS_REGION"

# Verificar VM
if ! podman machine list | grep -q "$VM_NAME.*Currently running"; then
    echo "🚀 Starting $VM_NAME..."
    podman machine start $VM_NAME
    sleep 5
fi

# Build da aplicação com profile aws
echo "📦 Building application with AWS profile..."
./mvnw clean package -DskipTests -Dspring-boot.run.profiles=aws -B

# Build imagem para ARM64 (local/dev)
echo "🐳 Building ARM64 image..."
podman build \
    --platform linux/arm64 \
    --format docker \
    --build-arg SPRING_PROFILES_ACTIVE=aws \
    --tag my-java-backend:${IMAGE_TAG}-arm64 \
    --tag my-java-backend:latest-arm64 \
    .

# Build imagem para AMD64 (AWS production)
echo "🐳 Building AMD64 image for AWS..."
podman build \
    --platform linux/amd64 \
    --format docker \
    --build-arg SPRING_PROFILES_ACTIVE=aws \
    --tag my-java-backend:${IMAGE_TAG}-amd64 \
    --tag my-java-backend:latest-amd64 \
    .

# Criar manifest multi-arch
echo "📋 Creating multi-arch manifest..."
podman manifest create my-java-backend:${IMAGE_TAG}
podman manifest add my-java-backend:${IMAGE_TAG} my-java-backend:${IMAGE_TAG}-arm64
podman manifest add my-java-backend:${IMAGE_TAG} my-java-backend:${IMAGE_TAG}-amd64

podman manifest create my-java-backend:latest
podman manifest add my-java-backend:latest my-java-backend:latest-arm64
podman manifest add my-java-backend:latest my-java-backend:latest-amd64

# Login no ECR
echo "🔐 Login no ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    podman login \
    --username AWS \
    --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Tag para ECR
echo "🏷️  Tagging for ECR..."
podman tag my-java-backend:${IMAGE_TAG} ${ECR_REPOSITORY}:${IMAGE_TAG}
podman tag my-java-backend:latest ${ECR_REPOSITORY}:latest

# Push manifest para ECR
echo "⬆️  Pushing multi-arch manifest to ECR..."
podman manifest push ${ECR_REPOSITORY}:${IMAGE_TAG}
podman manifest push ${ECR_REPOSITORY}:latest

# Verificar push
echo "✅ Images pushed to ECR"
aws ecr describe-images \
    --repository-name my-java-backend \
    --region ${AWS_REGION} \
    --query 'sort_by(imageDetails,& imagePushedAt)[-5:].[imageTags[0],imagePushedAt]' \
    --output table

# Invalidar cache do CloudFront
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo "🗑️  Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} \
        --paths "/*" \
        --region ${AWS_REGION}
    echo "✅ CloudFront cache invalidated"
fi

echo ""
echo "✅ Deployment completed successfully!"
echo "📝 Image Tag: ${IMAGE_TAG}"
echo "🏷️  Profile: aws"
echo "🌐 ECR: ${ECR_REPOSITORY}:${IMAGE_TAG}"
echo "🌐 ECR Latest: ${ECR_REPOSITORY}:latest"