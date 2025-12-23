#!/bin/bash

set -e

echo "🚀 Quick AWS Setup Script"
echo "========================="
echo ""

# Perguntar informações
read -p "Environment name (dev/staging/production): " ENVIRONMENT
read -p "AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
read -p "Database password (min 8 chars): " -s DB_PASSWORD
echo ""
read -p "SSL Certificate ARN (leave empty for HTTP only): " SSL_CERT_ARN

# Criar .env se não existir
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOF
# Environment
SPRING_PROFILES_ACTIVE=aws
ENVIRONMENT=${ENVIRONMENT}

# AWS Configuration
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Database
DB_NAME=myappdb
DB_USER=admin
DB_PASSWORD=${DB_PASSWORD}

# SSL Certificate
SSL_CERTIFICATE_ARN=${SSL_CERT_ARN}

# Application
SPRING_APPLICATION_NAME=my-java-backend
SERVER_PORT=8080
EOF
    echo "✅ .env created"
fi

# Criar terraform.tfvars
echo "📝 Creating Terraform variables..."
mkdir -p terraform/environments

cat > terraform/environments/${ENVIRONMENT}.tfvars << EOF
environment = "${ENVIRONMENT}"
aws_region  = "${AWS_REGION}"

# Project
project_name = "my-java-backend"

# Database
db_username = "admin"
db_password = "${DB_PASSWORD}"
db_name     = "myappdb"

# SSL Certificate
ssl_certificate_arn = "${SSL_CERT_ARN}"

# Network
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["${AWS_REGION}a", "${AWS_REGION}b"]
enable_nat_gateway = $([ "$ENVIRONMENT" == "production" ] && echo "true" || echo "false")

# ECS Configuration
ecs_instance_type    = "$([ "$ENVIRONMENT" == "production" ] && echo "t3.medium" || echo "t3.small")"
ecs_desired_capacity = $([ "$ENVIRONMENT" == "production" ] && echo "2" || echo "1")
ecs_min_capacity     = 1
ecs_max_capacity     = $([ "$ENVIRONMENT" == "production" ] && echo "10" || echo "3")

# Service
service_desired_count = $([ "$ENVIRONMENT" == "production" ] && echo "2" || echo "1")
service_min_count     = 1
service_max_count     = $([ "$ENVIRONMENT" == "production" ] && echo "10" || echo "5")

# Tasks
task_cpu    = "$([ "$ENVIRONMENT" == "production" ] && echo "1024" || echo "512")"
task_memory = "$([ "$ENVIRONMENT" == "production" ] && echo "2048" || echo "1024")"
EOF

echo "✅ Terraform variables created"
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Review terraform/environments/${ENVIRONMENT}.tfvars"
echo "  2. Run: ./scripts/deploy-full.sh ${ENVIRONMENT}"