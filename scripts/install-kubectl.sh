#!/usr/bin/env bash
set -euo pipefail

echo "###############"
echo "Install kubectl"
echo "###############"

ARCH=${1}
KUBECTL_VERSION=${2}

# Switch to a temporary folder
mkdir -p /tmp/k8s
cd /tmp/k8s

# Download the binary
curl -o kubectl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"

# Install it
install -o root -g root -m 0755 kubectl /bin/kubectl

# Remove the temporary files
rm -rf /tmp/k8s

# Test the installation
kubectl version --client=true
