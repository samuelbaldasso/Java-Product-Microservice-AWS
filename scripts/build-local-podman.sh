#!/bin/bash

set -e

echo "🧪 Building application locally with Podman Machine (ARM64) - AWS Profile..."

VM_NAME="podman-machine-default"

# Verificar se a VM está rodando
echo "🔍 Checking Podman Machine status..."
if ! podman machine list | grep -q "$VM_NAME.*Currently running"; then
    echo "🚀 Starting $VM_NAME..."
    podman machine start $VM_NAME
    sleep 5
fi

ARCH=$(uname -m)
echo "📊 Architecture: $ARCH"
echo "🏷️  Spring Profile: aws"

# Limpar cache de imagens antigas
echo "🧹 Cleaning old images..."
podman rmi my-java-backend:test 2>/dev/null || true
podman rmi my-java-backend:latest 2>/dev/null || true

# Pull das imagens base
echo "📥 Pre-pulling base images for ARM64..."
podman pull --platform linux/arm64 docker.io/amazoncorretto:17-alpine

echo "📦 Building Maven project with AWS profile..."
if [ ! -f "./mvnw" ]; then
    echo "❌ Maven wrapper not found!"
    echo "Creating Maven wrapper..."
    mvn wrapper:wrapper
fi

# Build Maven com profile aws
./mvnw clean package -DskipTests -Dspring-boot.run.profiles=aws -B

echo "🐳 Building Docker image with Podman..."
podman build \
    --platform linux/arm64 \
    --format docker \
    --pull=never \
    --build-arg SPRING_PROFILES_ACTIVE=aws \
    --tag my-java-backend:test \
    --tag my-java-backend:latest \
    --file Dockerfile \
    .

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Image built successfully with AWS profile!"
podman images | grep my-java-backend

# Limpar containers antigos
podman rm -f my-java-backend-test 2>/dev/null || true

# Run container com profile aws
echo "🚀 Starting container with AWS profile..."
podman run -d \
    --name my-java-backend-test \
    -p 8080:8080 \
    --platform linux/arm64 \
    --env SPRING_PROFILES_ACTIVE=aws \
    --env AWS_REGION=${AWS_REGION:-us-east-1} \
    --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    --env CLOUDFRONT_DISTRIBUTION_ID=${CLOUDFRONT_DISTRIBUTION_ID} \
    --env JAVA_OPTS="-Xmx512m -Xms256m -Dspring.profiles.active=aws" \
    my-java-backend:test

# Aguardar aplicação iniciar
echo "⏳ Waiting for application to start with AWS profile..."
MAX_ATTEMPTS=60
for i in $(seq 1 $MAX_ATTEMPTS); do
    if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Application started successfully with AWS profile!"
        break
    fi
    
    if [ $i -eq $MAX_ATTEMPTS ]; then
        echo "❌ Timeout waiting for application"
        echo "📋 Container logs:"
        podman logs my-java-backend-test
        podman stop my-java-backend-test
        podman rm my-java-backend-test
        exit 1
    fi
    
    printf "."
    sleep 2
done

echo ""

# Verificar profile ativo
echo "🔍 Checking active Spring profiles..."
podman logs my-java-backend-test | grep -i "active profiles" || echo "Profile check in logs..."

# Health check
echo "🏥 Running health check..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
echo "Response: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q "UP\|status"; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
    echo "📋 Container logs:"
    podman logs my-java-backend-test
    podman stop my-java-backend-test
    podman rm my-java-backend-test
    exit 1
fi

# Container info
echo ""
echo "📊 Container Status:"
podman ps | grep my-java-backend-test

echo ""
echo "🏷️  Active Profile: aws"
echo "📈 Resource Usage:"
podman stats --no-stream my-java-backend-test

echo ""
echo "📋 Recent Logs:"
podman logs my-java-backend-test | tail -n 30

echo ""
echo "✅ Container is running at http://localhost:8080"
echo ""
echo "📝 Useful commands:"
echo "  Logs:     podman logs -f my-java-backend-test"
echo "  Env:      podman exec my-java-backend-test env | grep SPRING"
echo "  Stop:     podman stop my-java-backend-test"
echo "  Remove:   podman rm -f my-java-backend-test"
echo "  Shell:    podman exec -it my-java-backend-test sh"
echo ""

# Perguntar se quer manter rodando
read -p "🤔 Keep container running? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "🧹 Cleaning up..."
    podman stop my-java-backend-test
    podman rm my-java-backend-test
    echo "✅ Cleanup completed!"
fi

echo "✅ Build and test completed successfully with AWS profile!"