#!/bin/bash

echo "🛑 Stopping all chaos tests..."

# Stop Pod Chaos
echo "Stopping Pod Chaos..."
kubectl delete podchaos --all

# Stop Network Chaos
echo "Stopping Network Chaos..."
kubectl delete networkchaos --all

# Stop Stress Chaos
echo "Stopping Stress Chaos..."
kubectl delete stresschaos --all

# Stop IO Chaos
echo "Stopping IO Chaos..."
kubectl delete iochaos --all

# Verify all chaos resources are removed
echo "Verifying cleanup..."
kubectl get podchaos,networkchaos,stresschaos,iochaos

echo "✅ All chaos tests stopped"