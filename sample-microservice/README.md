# Simple Microservice with Chaos Testing

A basic Node.js microservice with Kubernetes deployment and chaos testing configuration.

## Prerequisites

- Node.js 14+
- Docker
- Kubernetes cluster
- Chaos Mesh installed
- kubectl configured

## Setup Steps

### 1. Local Development

```bash
# Install dependencies
npm install

# Run locally
npm start
```

### 2. Kubernetes Deployment

```bash
# Build Docker image
docker build -t sample-microservice:latest .

# Deploy to Kubernetes
kubectl apply -f k8s/

# Verify deployment
kubectl get pods -l app=sample-microservice
kubectl get svc sample-microservice
```

### 3. Chaos Testing Setup

1. Install Chaos Mesh:

```bash
curl -sSL https://mirrors.chaos-mesh.org/v2.5.1/install.sh | bash
```

2. Verify installation:

```bash
kubectl get pods -n chaos-testing
```

### 4. Running Chaos Tests

```bash
# Start monitoring
./scripts/chaos-monitor.sh

# Run chaos tests
./manual-chaos-test/manual-acert-testing.sh

# Stop all tests
./scripts/stop-all-tests.sh
```

### 5. Cleanup

```bash
kubectl apply -f scripts/stop-all-pods-services.yaml
```

## Architecture

The service exposes a REST API on port 3000 with the following endpoints:

- GET /health - Health check endpoint
- GET /metrics - Basic metrics endpoint

## Monitoring

Use chaos-monitor.sh to track:

- HTTP response status
- Response times
- Pod count
- Resource usage
