#!/bin/bash

echo "🚀 Starting A-CERT Chaos Tests"

# Pod Chaos
echo "📦 Running Pod Chaos Test..."
kubectl apply -f pod-chaos.yaml
sleep 60
kubectl delete podchaos pod-kill-test

# Network Latency  
echo "🌐 Running Network Latency Test..."
kubectl apply -f network-latency.yaml
sleep 120
kubectl delete networkchaos network-latency-test

# Network Loss
echo "🌐 Running Network Loss Test..."
kubectl apply -f network-loss.yaml
sleep 60
kubectl delete networkchaos network-loss-test

# CPU Stress
echo "🔥 Running CPU Stress Test..."
kubectl apply -f cpu-stress.yaml
sleep 120
kubectl delete stresschaos cpu-stress-test



# memory Stress
echo "🔥 Running Memory Stress Test..."
kubectl apply -f memory-stress.yaml
sleep 120
kubectl delete stresschaos memory-stress-test

# I/O Stress  
echo "🌐 Running I/O stress Test..."
kubectl apply -f io-stress.yaml
sleep 120
kubectl delete iochaos io-stress-test

echo "✅ A-CERT Tests Complete"