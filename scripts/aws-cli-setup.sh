# 1. Instalar AWS CLI (se ainda não tiver)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 2. Verificar instalação
aws --version

# 3. Configurar credenciais AWS
aws configure
# AWS Access Key ID: [sua key]
# AWS Secret Access Key: [sua secret]
# Default region name: us-east-1
# Default output format: json

# 4. Testar credenciais
aws sts get-caller-identity

# Clone/navegue para o projeto
cd 

# Criar e configurar .env
cat > .env << 'EOF'
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Spring
SPRING_PROFILES_ACTIVE=aws
SPRING_APPLICATION_NAME=my-java-backend

# Database (será criado pelo Terraform)
DB_NAME=myapp
DB_USER=admin
DB_PASSWORD=ChangeMe123!SecurePassword

# Build
PROJECT_NAME=my-java-backend
ENVIRONMENT=production
EOF

# Carregar variáveis
source .env

# Exportar AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# 2.1 - Criar bucket S3 para Terraform state
BUCKET_NAME="terraform-state-${AWS_ACCOUNT_ID}-${AWS_REGION}"

aws s3 mb s3://${BUCKET_NAME} --region ${AWS_REGION}

# Habilitar versionamento
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_NAME} \
    --versioning-configuration Status=Enabled

# Habilitar encryption
aws s3api put-bucket-encryption \
    --bucket ${BUCKET_NAME} \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            },
            "BucketKeyEnabled": true
        }]
    }'

# 2.2 - Criar DynamoDB table para lock
aws dynamodb create-table \
    --table-name terraform-lock-${ENVIRONMENT} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ${AWS_REGION}

echo "✅ Terraform backend configurado!"

# 3.1 - Solicitar certificado SSL no ACM
# Substitua seu-dominio.com pelo seu domínio real

CERTIFICATE_ARN=$(aws acm request-certificate \
    --domain-name "*.seu-dominio.com" \
    --subject-alternative-names "seu-dominio.com" \
    --validation-method DNS \
    --region ${AWS_REGION} \
    --query 'CertificateArn' \
    --output text)

echo "Certificate ARN: $CERTIFICATE_ARN"

# 3.2 - Obter registro DNS para validação
aws acm describe-certificate \
    --certificate-arn ${CERTIFICATE_ARN} \
    --region ${AWS_REGION} \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
    --output table

# ⚠️ IMPORTANTE: Adicione esse registro CNAME no seu DNS provider
# Aguarde a validação (pode levar até 30 minutos)

# 3.3 - Verificar status da validação
aws acm describe-certificate \
    --certificate-arn ${CERTIFICATE_ARN} \
    --region ${AWS_REGION} \
    --query 'Certificate.Status' \
    --output text

# Se não tiver domínio próprio, use certificado auto-assinado temporário
# (apenas para testes, não para produção)
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
