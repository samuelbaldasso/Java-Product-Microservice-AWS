#!/bin/bash

echo "🔍 Checking AWS Credentials..."
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not installed"
    echo "Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo "✅ AWS CLI installed: $(aws --version)"
echo ""

# Check credentials file
if [ -f ~/.aws/credentials ]; then
    echo "✅ Credentials file exists: ~/.aws/credentials"
    
    if grep -q "aws_access_key_id" ~/.aws/credentials; then
        echo "✅ Access Key ID configured"
    else
        echo "❌ Access Key ID not found in credentials"
    fi
    
    if grep -q "aws_secret_access_key" ~/.aws/credentials; then
        echo "✅ Secret Access Key configured"
    else
        echo "❌ Secret Access Key not found in credentials"
    fi
else
    echo "❌ Credentials file not found: ~/.aws/credentials"
    echo "Run: aws configure"
    exit 1
fi

echo ""

# Check config file
if [ -f ~/.aws/config ]; then
    echo "✅ Config file exists: ~/.aws/config"
    REGION=$(aws configure get region)
    echo "   Region: ${REGION:-Not set}"
else
    echo "⚠️  Config file not found: ~/.aws/config"
fi

echo ""

# Test credentials
echo "🧪 Testing credentials..."
if IDENTITY=$(aws sts get-caller-identity 2>&1); then
    echo "✅ Credentials are valid!"
    echo ""
    echo "$IDENTITY" | jq .
    
    ACCOUNT_ID=$(echo "$IDENTITY" | jq -r .Account)
    echo ""
    echo "📝 Your AWS Account ID: $ACCOUNT_ID"
    
    # Update .env if exists
    if [ -f .env ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/AWS_ACCOUNT_ID=.*/AWS_ACCOUNT_ID=${ACCOUNT_ID}/" .env
        else
            sed -i "s/AWS_ACCOUNT_ID=.*/AWS_ACCOUNT_ID=${ACCOUNT_ID}/" .env
        fi
        echo "✅ Updated .env with Account ID"
    fi
else
    echo "❌ Credentials test failed!"
    echo "$IDENTITY"
    echo ""
    echo "Common issues:"
    echo "  1. Access Key expired or invalid"
    echo "  2. Secret Key incorrect"
    echo "  3. IAM user doesn't have permissions"
    echo ""
    echo "Fix: Run 'aws configure' and enter valid credentials"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ AWS credentials are configured correctly!"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/deploy-aws.sh dev"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"