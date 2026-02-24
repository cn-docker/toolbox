#!/usr/bin/env bash
set -euo pipefail

echo "###############"
echo "Install AWS Cli"
echo "###############"

TARGETARCH=${1}
AWS_CLI_VERSION=${2}

# Map TARGETARCH to upstream names
# TARGETARCH values: "amd64", "arm64" (buildx provides these)
# AWS uses x86_64 / aarch64
case "${TARGETARCH}" in
  amd64)
    ARCH="x86_64"
    ;;
  arm64)
    ARCH="aarch64"
    ;;
  *)
    echo "unsupported arch: ${TARGETARCH}"
    exit 1
    ;;
esac

# Switch to a temporary folder
mkdir -p /tmp/aws
cd /tmp/aws

# Download the package
curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" -o awscliv2.zip

# Download the signature
curl -o awscliv2.sig "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip.sig"

# Verify the signatures
gpg --verify awscliv2.sig awscliv2.zip

# Unzip it
unzip awscliv2.zip

# Install it
./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && \

# Remove the temporary files
rm -rf /tmp/aws

# Test the installation
aws --version
