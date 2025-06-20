#!/bin/bash

echo "🛑 Stopping Sample Microservice Deployments and Services..."

kubectl delete deployment sample-microservice
kubectl delete service sample-microservice

echo "✅ Sample Microservice deployments and services stopped."