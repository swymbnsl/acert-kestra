#!/bin/bash

# Resolve the script directory (so it's independent of where it's run from)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../manual-chaos-test/results"

THRESHOLD_RESPONSE_TIME=500   # in ms
THRESHOLD_ERROR_RATE=0.05     # 5%

approved=true
failed_tests#!/bin/bash

# Resolve the script directory (so it's independent of where it's run from)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../manual-chaos-test/results"

THRESHOLD_RESPONSE_TIME=500   # in ms
THRESHOLD_ERROR_RATE=0.05     # 5%

approved=true
failed_tests=()

# Check if jq and bc are installed
for cmd in jq bc; do
    if ! command -v $cmd &>/dev/null; then
        echo "❌ Error: Required tool '$cmd' is not installed."
        exit 1
    fi
done

# Check if results directory exists and has any JSON files
shopt -s nullglob
json_files=("$RESULTS_DIR"/*.json)
shopt -u nullglob

if [ ${#json_files[@]} -eq 0 ]; then
    echo "❌ No result files found in '$RESULTS_DIR'."
    echo "approved=false"
    exit 1
fi

echo "📊 A-CERT Chaos Test Results Analysis"
echo "====================================="

for file in "${json_files[@]}"; do
    test_name=$(basename "$file" .json)

    # Extract stats using correct Artillery JSON structure
    avg_rt=$(jq -r '.aggregate.summaries."http.response_time".mean // 0' "$file")
    p95_rt=$(jq -r '.aggregate.summaries."http.response_time".p95 // 0' "$file")
    p99_rt=$(jq -r '.aggregate.summaries."http.response_time".p99 // 0' "$file")
    
    timeout_errors=$(jq -r '.aggregate.counters."errors.ETIMEDOUT" // 0' "$file")
    total_requests=$(jq -r '.aggregate.counters."http.requests" // 0' "$file")
    successful_responses=$(jq -r '.aggregate.counters."http.responses" // 0' "$file")
    failed_users=$(jq -r '.aggregate.counters."vusers.failed" // 0' "$file")
    
    # Calculate error rate
    if [ "$total_requests" -gt 0 ]; then
        error_rate=$(awk "BEGIN {printf \"%.4f\", $timeout_errors/$total_requests}")
        success_rate=$(awk "BEGIN {printf \"%.2f\", $successful_responses/$total_requests * 100}")
    else
        error_rate="0.0000"
        success_rate="0.00"
    fi

    echo "📄 Test: $test_name"
    echo "   ➤ Total Requests: $total_requests"
    echo "   ➤ Successful Responses: $successful_responses"
    echo "   ➤ Failed Users: $failed_users"
    echo "   ➤ Timeout Errors: $timeout_errors"
    echo "   ➤ Success Rate: ${success_rate}%"
    echo "   ➤ Avg Response Time: ${avg_rt} ms"
    echo "   ➤ P95 Response Time: ${p95_rt} ms"
    echo "   ➤ P99 Response Time: ${p99_rt} ms"
    echo "   ➤ Error Rate: ${error_rate} (${timeout_errors}/${total_requests})"

    rt_failed=false
    error_failed=false
    
    if (( $(echo "$avg_rt > $THRESHOLD_RESPONSE_TIME" | bc -l) )); then
        rt_failed=true
    fi

    if (( $(echo "$error_rate > $THRESHOLD_ERROR_RATE" | bc -l) )); then
        error_failed=true
    fi

    if [ "$rt_failed" = true ] || [ "$error_failed" = true ]; then
        echo "   ❌ FAILED"
        [ "$rt_failed" = true ] && echo "      - Response time exceeded: ${avg_rt}ms > ${THRESHOLD_RESPONSE_TIME}ms"
        [ "$error_failed" = true ] && echo "      - Error rate exceeded: ${error_rate} > ${THRESHOLD_ERROR_RATE}"
        failed_tests+=("$test_name")
        approved=false
    else
        echo "   ✅ PASSED"
    fi

    echo ""
done

echo "=============================="
echo "📋 SUMMARY"
echo "=============================="
echo "Thresholds:"
echo "  - Max Response Time: ${THRESHOLD_RESPONSE_TIME}ms"
echo "  - Max Error Rate: ${THRESHOLD_ERROR_RATE} (${THRESHOLD_ERROR_RATE%.*}%)"
echo ""

if [ "$approved" = true ]; then
    echo "🎉 All tests passed thresholds!"
    echo "approved=true"
    exit 0
else
    echo "❌ Tests failed: ${#failed_tests[@]} out of ${#json_files[@]}"
    for name in "${failed_tests[@]}"; do
        echo "   - $name"
    done
    echo "approved=false"
    exit 1
fi
=()

# Check if jq and bc are installed
for cmd in jq bc; do
    if ! command -v $cmd &>/dev/null; then
        echo "❌ Error: Required tool '$cmd' is not installed."
        exit 1
    fi
done

# Check if results directory exists and has any JSON files
shopt -s nullglob
json_files=("$RESULTS_DIR"/*.json)
shopt -u nullglob

if [ ${#json_files[@]} -eq 0 ]; then
    echo "❌ No result files found in '$RESULTS_DIR'."
    echo "approved=false"
    exit 1
fi

echo "📊 A-CERT Chaos Test Results Analysis"
echo "====================================="

for file in "${json_files[@]}"; do
    test_name=$(basename "$file" .json)

    # Extract stats using correct Artillery JSON structure
    avg_rt=$(jq -r '.aggregate.summaries."http.response_time".mean // 0' "$file")
    p95_rt=$(jq -r '.aggregate.summaries."http.response_time".p95 // 0' "$file")
    p99_rt=$(jq -r '.aggregate.summaries."http.response_time".p99 // 0' "$file")
    
    timeout_errors=$(jq -r '.aggregate.counters."errors.ETIMEDOUT" // 0' "$file")
    total_requests=$(jq -r '.aggregate.counters."http.requests" // 0' "$file")
    successful_responses=$(jq -r '.aggregate.counters."http.responses" // 0' "$file")
    failed_users=$(jq -r '.aggregate.counters."vusers.failed" // 0' "$file")
    
    # Calculate error rate
    if [ "$total_requests" -gt 0 ]; then
        error_rate=$(awk "BEGIN {printf \"%.4f\", $timeout_errors/$total_requests}")
        success_rate=$(awk "BEGIN {printf \"%.2f\", $successful_responses/$total_requests * 100}")
    else
        error_rate="0.0000"
        success_rate="0.00"
    fi

    echo "📄 Test: $test_name"
    echo "   ➤ Total Requests: $total_requests"
    echo "   ➤ Successful Responses: $successful_responses"
    echo "   ➤ Failed Users: $failed_users"
    echo "   ➤ Timeout Errors: $timeout_errors"
    echo "   ➤ Success Rate: ${success_rate}%"
    echo "   ➤ Avg Response Time: ${avg_rt} ms"
    echo "   ➤ P95 Response Time: ${p95_rt} ms"
    echo "   ➤ P99 Response Time: ${p99_rt} ms"
    echo "   ➤ Error Rate: ${error_rate} (${timeout_errors}/${total_requests})"

    rt_failed=false
    error_failed=false
    
    if (( $(echo "$avg_rt > $THRESHOLD_RESPONSE_TIME" | bc -l) )); then
        rt_failed=true
    fi

    if (( $(echo "$error_rate > $THRESHOLD_ERROR_RATE" | bc -l) )); then
        error_failed=true
    fi

    if [ "$rt_failed" = true ] || [ "$error_failed" = true ]; then
        echo "   ❌ FAILED"
        [ "$rt_failed" = true ] && echo "      - Response time exceeded: ${avg_rt}ms > ${THRESHOLD_RESPONSE_TIME}ms"
        [ "$error_failed" = true ] && echo "      - Error rate exceeded: ${error_rate} > ${THRESHOLD_ERROR_RATE}"
        failed_tests+=("$test_name")
        approved=false
    else
        echo "   ✅ PASSED"
    fi

    echo ""
done

echo "=============================="
echo "📋 SUMMARY"
echo "=============================="
echo "Thresholds:"
echo "  - Max Response Time: ${THRESHOLD_RESPONSE_TIME}ms"
echo "  - Max Error Rate: ${THRESHOLD_ERROR_RATE} (${THRESHOLD_ERROR_RATE%.*}%)"
echo ""

if [ "$approved" = true ]; then
    echo "🎉 All tests passed thresholds!"
    echo "approved=true"
    exit 0
else
    echo "❌ Tests failed: ${#failed_tests[@]} out of ${#json_files[@]}"
    for name in "${failed_tests[@]}"; do
        echo "   - $name"
    done
    echo "approved=false"
    exit 1
fi
