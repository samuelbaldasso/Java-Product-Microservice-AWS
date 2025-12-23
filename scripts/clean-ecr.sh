#!/bin/bash

set -e

ENVIRONMENT=${1:-production}
AWS_REGION=${AWS_REGION:-us-east-1}
REPOSITORY_NAME="my-java-backend-${ENVIRONMENT}"

echo "🧹 Cleaning old ECR images from ${REPOSITORY_NAME}..."

# Get images older than 30 days
OLD_IMAGES=$(aws ecr describe-images \
    --repository-name ${REPOSITORY_NAME} \
    --region ${AWS_REGION} \
    --query 'sort_by(imageDetails,& imagePushedAt)[:-10].[imageDigest]' \
    --output text)

if [ -z "$OLD_IMAGES" ]; then
    echo "✅ No old images to clean"
    exit 0
fi

# Delete old images
echo "🗑️  Deleting old images..."
for DIGEST in $OLD_IMAGES; do
    aws ecr batch-delete-image \
        --repository-name ${REPOSITORY_NAME} \
        --region ${AWS_REGION} \
        --image-ids imageDigest=${DIGEST}
    echo "  Deleted: ${DIGEST}"
done

echo "✅ Cleanup completed!"