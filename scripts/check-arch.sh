#!/bin/bash

echo "🔍 Checking architecture support..."
echo ""

echo "=== Local Architecture ==="
uname -m
echo ""

echo "=== Podman Version ==="
podman --version
echo ""

echo "=== Podman Machine Info ==="
podman machine info
echo ""

echo "=== Testing multi-arch build ==="
echo "Building test image..."
cat > Dockerfile.test << 'EOF'
FROM alpine:latest
RUN echo "Architecture: $(uname -m)"
CMD ["echo", "Hello from container"]
EOF

podman build -f Dockerfile.test --platform linux/arm64 -t test:arm64 . && echo "✅ ARM64 build works"
podman build -f Dockerfile.test --platform linux/amd64 -t test:amd64 . && echo "✅ AMD64 build works"

rm Dockerfile.test

echo ""
echo "✅ Architecture check completed!"