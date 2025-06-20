# Simple Microservice

A basic Node.js microservice with Kubernetes deployment configuration.

## Building and Running Locally

1. Install dependencies:

```bash
npm install
```

2. Run the service:

```bash
npm start
```

## Building and Deploying to Kubernetes

1. Build the Docker image:

```bash
docker build -t simple-microservice:1.0.0 .
```

2. Deploy to Kubernetes:

```bash
kubectl apply -f k8s/
```

3. Verify deployment:

```bash
kubectl get pods
kubectl get services
```

The service will be available through the NodePort service. Get the port with:

```bash
kubectl get svc simple-microservice
```
