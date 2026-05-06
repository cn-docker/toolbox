##############
# Dependencies
##############
FROM hashicorp/terraform:1.14 AS terraform
FROM fullstorydev/grpcurl:v1.9.3 AS grpcurl

#################
# Build Go Binary
#################
FROM golang:1.26-alpine AS build
WORKDIR /app
COPY src/ .
RUN go build -o toolbox

#######
# Image
#######
FROM ubuntu:24.04
LABEL maintainer="Julian Nonino <noninojulian@gmail.com>"

# Args
ARG TARGETARCH
# renovate: datasource=github-tags depName=aws/aws-cli extractVersion=(?<version>.*)$
ARG AWS_CLI_VERSION=2.34.44
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.35.1

# Envs
ENV DEBIAN_FRONTEND=noninteractive

# Copy dependencies
COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=grpcurl /bin/grpcurl /bin/grpcurl

# Install Tools
RUN apt update && \
    apt install -y ca-certificates curl dnsutils git gnupg groff iproute2 iputils-ping jq less lsb-release netcat-openbsd nmap snapd telnet traceroute unzip wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY scripts/* .

# Install AWS Cli
RUN gpg --import aws-cli-public-key-file && \
    ./install-aws-cli.sh ${TARGETARCH} ${AWS_CLI_VERSION}

# Install Kubectl
RUN ./install-kubectl.sh ${TARGETARCH} ${KUBECTL_VERSION}

# Run the server
WORKDIR /app
COPY --from=build /app/toolbox /bin/toolbox
EXPOSE 8080
CMD ["/bin/toolbox"]
