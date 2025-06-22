#!/bin/bash

# Get the absolute path of the directory where the script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Clean and create results directory
echo "🧹 Cleaning previous results..."
rm -rf results
mkdir -p results

# Base Configuration
APP_URL="http://sample.local/"
DURATION=5  # in seconds

# Function to run artillery test
run_artillery_test() {
    local label="$1"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local output_file="results/${label}.json"
    
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

# Function to safely cleanup chaos resources
cleanup_chaos() {
    local kind="$1"
    local name="$2"
    local key="$3"
    
    echo "🧹 Cleaning up Chaos: $key"
    
    if kubectl delete "$kind" "$name" --timeout=30s; then
        echo "✅ Successfully cleaned up $key"
    else
        echo "⚠️  Warning: Failed to clean up $key, forcing deletion..."
        kubectl delete "$kind" "$name" --force --grace-period=0 2>/dev/null || true
    fi
    
    echo "⏳ Waiting for cleanup to complete..."
    sleep 5
}

# 🔹 Baseline test before chaos
echo "🚀 Starting Baseline Load Test (No Chaos)"
run_artillery_test "baseline"

# 🔹 Define chaos tests (fixed io-stress resource type)
declare -A CHAOS_TESTS=(
  ["podchaos"]="pod-chaos.yaml podchaos pod-kill-test"
  ["network-latency"]="network-latency.yaml networkchaos network-latency-test"
  ["network-loss"]="network-loss.yaml networkchaos network-loss-test"
  ["cpu-stress"]="cpu-stress.yaml stresschaos cpu-stress-test"
  ["memory-stress"]="memory-stress.yaml stresschaos memory-stress-test"
)

# 🔹 Run each chaos test one by one
for key in "${!CHAOS_TESTS[@]}"; do
    IFS=' ' read -r yaml kind name <<< "${CHAOS_TESTS[$key]}"
    YAML_PATH="${SCRIPT_DIR}/${yaml}"

    echo ""
    echo "💥 Applying Chaos Test: $key"
    
    if [[ ! -f "$YAML_PATH" ]]; then
        echo "❌ Error: $YAML_PATH not found, skipping $key test"
        continue
    fi

    if kubectl apply -f "$YAML_PATH"; then
        echo "✅ Successfully applied $key chaos"
    else
        echo "❌ Failed to apply $key chaos, skipping..."
        continue
    fi

    echo "🕒 Waiting 5s before load test..."
    sleep 5

    run_artillery_test "$key"

    cleanup_chaos "$kind" "$name" "$key"

    echo "⏳ Waiting 10s before next test..."
    sleep 10
done

echo ""
echo "🎉 All Chaos Tests Completed!"
echo "📊 Results saved in: ./results/"
ls -la results/
