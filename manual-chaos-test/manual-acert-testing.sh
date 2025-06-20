#!/bin/bash

# Create results directory
mkdir -p results

# Base Configuration
APP_URL="http://127.0.0.1:39779"
DURATION=60  # in seconds

# Function to run artillery test
run_artillery_test() {
    local label="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local output_file="results/${label}-${timestamp}.json"

    # Generate temporary Artillery config
    cat > artillery-config.yml <<EOF
config:
  target: "${APP_URL}"
  phases:
    - duration: ${DURATION}
      arrivalRate: 10
  plugins:
    metrics-by-endpoint: {}
scenarios:
  - flow:
      - get:
          url: "/"
EOF

    echo "🧪 Running Artillery Test: $label"
    artillery run artillery-config.yml --output "$output_file"
    echo "✅ Saved to $output_file"
    rm artillery-config.yml
}

# 🔹 Baseline test before chaos
echo "🚀 Starting Baseline Load Test (No Chaos)"
run_artillery_test "baseline"

# 🔹 Define chaos tests
declare -A CHAOS_TESTS=(
  ["podchaos"]="pod-chaos.yaml podchaos pod-kill-test"
  ["network-latency"]="network-latency.yaml networkchaos network-latency-test"
  ["network-loss"]="network-loss.yaml networkchaos network-loss-test"
  ["cpu-stress"]="cpu-stress.yaml stresschaos cpu-stress-test"
  ["memory-stress"]="memory-stress.yaml stresschaos memory-stress-test"
  ["io-stress"]="io-stress.yaml iochaos io-stress-test"
)

# 🔹 Run each chaos test one by one
for key in "${!CHAOS_TESTS[@]}"; do
    IFS=' ' read -r yaml kind name <<< "${CHAOS_TESTS[$key]}"

    echo ""
    echo "💥 Applying Chaos Test: $key"
    kubectl apply -f "$yaml"

    echo "🕒 Waiting 5s before load test..."
    sleep 5

    # Run artillery in background and wait
    run_artillery_test "$key"

    echo "🧹 Cleaning up Chaos: $key"
    kubectl delete "$kind" "$name"

    echo "⏳ Waiting 10s before next test..."
    sleep 10
done

echo ""
echo "🎉 All Chaos Tests Completed!"
