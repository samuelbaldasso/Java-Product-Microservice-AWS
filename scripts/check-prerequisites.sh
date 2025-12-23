#!/bin/bash

echo "🔍 Checking prerequisites..."

MISSING=0

# Check AWS CLI
if command -v aws &> /dev/null; then
    echo "✅ AWS CLI installed: $(aws --version)"
else
    echo "❌ AWS CLI not installed"
    echo "   Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    MISSING=1
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    echo "✅ Terraform installed: $(terraform version | head -n1)"
else
    echo "❌ Terraform not installed"
    echo "   Install: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    MISSING=1
fi

# Check Podman
if command -v podman &> /dev/null; then
    echo "✅ Podman installed: $(podman --version)"
else
    echo "❌ Podman not installed"
    echo "   Install: https://podman.io/getting-started/installation"
    MISSING=1
fi

# Check Java
if command -v java &> /dev/null; then
    echo "✅ Java installed: $(java -version 2>&1 | head -n1)"
else
    echo "❌ Java not installed"
    MISSING=1
fi

# Check Maven
if command -v mvn &> /dev/null || [ -f "./mvnw" ]; then
    echo "✅ Maven available"
else
    echo "❌ Maven not installed and no wrapper found"
    MISSING=1
fi

# Check jq
if command -v jq &> /dev/null; then
    echo "✅ jq installed"
else
    echo "❌ jq not installed"
    echo "   Install: brew install jq (Mac) or apt install jq (Linux)"
    MISSING=1
fi

if [ $MISSING -eq 0 ]; then
    echo ""
    echo "✅ All prerequisites met!"
else
    echo ""
    echo "❌ Please install missing tools before proceeding"
    exit 1
fi