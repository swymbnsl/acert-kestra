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

### 2. Docker Setup

```bash
# Create Dockerfile if not exists
cat > Dockerfile << EOF
FROM node:14-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# Build Docker image
docker build -t sample-microservice:latest .

# Test the image locally
docker run -p 3000:3000 sample-microservice:latest
```

### 3. Kubernetes Deployment

```bash
# Create namespace if not exists
kubectl create namespace sample-app

# Deploy the application
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify deployment
kubectl get pods -n sample-app -l app=sample-microservice
kubectl get svc -n sample-app sample-microservice

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=sample-microservice -n sample-app --timeout=120s
```

### 4. Chaos Mesh Setup

```bash
# Install Chaos Mesh
curl -sSL https://mirrors.chaos-mesh.org/v2.5.1/install.sh | bash

# Verify installation
kubectl get pods -n chaos-testing

# Configure RBAC for Chaos Mesh
kubectl apply -f k8s/chaos-rbac.yaml
```

### 5. Running Chaos Tests

```bash
# Start monitoring in a separate terminal
./scripts/chaos-monitor.sh

# Wait for monitoring to initialize (about 30 seconds)
sleep 30

# Run the chaos tests
./manual-chaos-test/manual-acert-testing.sh

# View real-time metrics during the test
kubectl logs -f -n chaos-testing $(kubectl get pods -n chaos-testing -l app=chaos-monitor -o jsonpath='{.items[0].metadata.name}')
```

### 6. Chaos Scoring

```bash
# Generate chaos test scores
./scripts/chaos-scoring.sh

# View the scoring report
cat ./reports/chaos-score-report.txt
```

### 7. Cleanup

```bash
# Stop all chaos experiments
./scripts/stop-all-tests.sh

# Remove application and services
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml

# Remove monitoring resources
kubectl delete -f scripts/stop-all-pods-services.yaml

# Optional: Uninstall Chaos Mesh
helm uninstall chaos-mesh -n chaos-testing
kubectl delete namespace chaos-testing
```

## Architecture

The service exposes a REST API on port 3000 with the following endpoints:

- GET /health - Health check endpoint

## Monitoring

Use chaos-monitor.sh to track:

- HTTP response status
- Response times
- Pod count
- Resource usage

## Test Reports

Chaos test reports are generated in the `./reports` directory and include:

- Test execution logs
- Metrics data
- Chaos score analysis
- Resilience recommendations
