#!/bin/bash

set -e

echo "=== Local Security Scan ==="
echo ""

echo "1. Running npm audit..."
npm audit --audit-level=moderate || echo "⚠️  npm audit found issues"
echo ""

echo "2. Running ESLint..."
npm run lint || echo "⚠️  ESLint found issues"
echo ""

echo "3. Running Trivy (if installed)..."
if command -v trivy &> /dev/null; then
    trivy fs . --severity CRITICAL,HIGH,MEDIUM || echo "⚠️  Trivy found vulnerabilities"
else
    echo "⚠️  Trivy not installed. Install with: brew install trivy"
fi
echo ""

echo "4. Running Docker image scan (if image exists)..."
if docker images | grep -q "cloud-native-demo"; then
    if command -v trivy &> /dev/null; then
        trivy image cloud-native-demo:latest --severity CRITICAL,HIGH,MEDIUM || echo "⚠️  Docker image scan found issues"
    else
        echo "⚠️  Trivy not installed for Docker image scan"
    fi
else
    echo "⚠️  Docker image not found. Build with: docker build -t cloud-native-demo:latest ."
fi

echo ""
echo "=== Security Scan Complete ==="
