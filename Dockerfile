##############
# Dependencies
##############
FROM hashicorp/terraform:1.14 AS terraform
FROM fullstorydev/grpcurl:v1.9.3 AS grpcurl

#################
# Build Go Binary
#################
FROM golang:1.25-alpine3.21 AS build
WORKDIR /app
COPY src/ .
RUN go build -o toolbox

############
# Base image
############
FROM ubuntu:24.04 AS base

# Args
ARG TARGETARCH
# renovate: datasource=github-tags depName=aws/aws-cli extractVersion=(?<version>.*)$
ARG AWS_CLI_VERSION=2.33.28
ARG KUBECTL_VERSION=v1.34.0

# Envs
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates curl unzip gnupg lsb-release && \
    rm -rf /var/lib/apt/lists/*

# Map TARGETARCH to upstream names
# TARGETARCH values: "amd64", "arm64" (buildx provides these)
# AWS uses x86_64 / aarch64; kubectl uses amd64 / arm64
RUN case "${TARGETARCH}" in \
      amd64) ARCH="amd64"; AWS_ARCH="x86_64"; ;; \
      arm64) ARCH="arm64"; AWS_ARCH="aarch64"; ;; \
      *) echo "unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    echo "TARGETARCH=${TARGETARCH} -> ARCH=${ARCH}, AWS_ARCH=${AWS_ARCH}" && \
    export ARCH AWS_ARCH

# Install AWS Cli
RUN AWS_ZIP_FILE_NANE="awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip"; \
    curl "https://awscli.amazonaws.com/${AWS_ZIP_FILE_NANE}" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && \
    rm -rf /tmp/awscliv2.zip /tmp/aws; \
    aws --version

# Install Kubectl
ENV KUBECTL_VERSION=v1.34.0
RUN curl -o /tmp/kubectl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 /tmp/kubectl /bin/kubectl && \
    rm /tmp/kubectl; \
    kubectl version --client --short

#######
# Image
#######
FROM ubuntu:24.04
LABEL maintainer="Julian Nonino <noninojulian@gmail.com>"

# Copy dependencies
COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=grpcurl /bin/grpcurl /bin/grpcurl
COPY --from=base /bin/kubectl /bin/kubectl
COPY --from=base /usr/local/bin/aws /usr/local/bin/aws
COPY --from=base /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/dist/aws /usr/local/bin/aws || true

# Install Tools
RUN apt update && \
    apt install -y curl dnsutils git groff iproute2 iputils-ping jq less netcat-openbsd nmap snapd telnet traceroute unzip wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Run the server
WORKDIR /app
COPY --from=build /app/toolbox /bin/toolbox
EXPOSE 8080
CMD ["/bin/toolbox"]
