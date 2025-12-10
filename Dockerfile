# Dependencies
FROM hashicorp/terraform:1.14 AS terraform
FROM fullstorydev/grpcurl:v1.9.3 AS grpcurl

#################
# Build Go Binary
FROM golang:1.25-alpine3.21 AS build
WORKDIR /app
COPY src/ .
RUN go build -o toolbox

#######
# Image
FROM debian:13-slim
LABEL maintainer="Julian Nonino <noninojulian@gmail.com>"

# Args
ARG TARGETARCH

# Copy dependencies
COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=grpcurl /bin/grpcurl /bin/grpcurl

# Install Tools
RUN apt update && \
    apt install -y curl git iproute2 iputils-ping netcat-openbsd nmap telnet traceroute wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Environment
ENV ARCH=${TARGETARCH}

# Install Kubectl
ENV KUBECTL_VERSION=v1.34.0
RUN curl -o /tmp/kubectl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 /tmp/kubectl /bin/kubectl && \
    rm /tmp/kubectl

# Run the server
WORKDIR /app
COPY --from=build /app/toolbox /bin/toolbox
EXPOSE 8080
CMD ["/bin/toolbox"]
