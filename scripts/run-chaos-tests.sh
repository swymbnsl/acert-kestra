#!/bin/bash

# Resolve the absolute path of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "🌀 Starting chaos testing sequence..."

# Configuration
RESULT_ENDPOINT="http://localhost:9999/result"
START_TIME=$(date +%s)
TEST_ID="chaos_test_$(date +%Y%m%d_%H%M%S)"

# Path to manual and scoring scripts
MANUAL_SCRIPT="$SCRIPT_DIR/../manual-chaos-test/manual-acert-testing.sh"
SCORING_SCRIPT="$SCRIPT_DIR/chaos-scoring.sh"

# Initialize result data
declare -A result_data
result_data[test_id]="$TEST_ID"
result_data[start_time]="$(date -d @$START_TIME -Iseconds)"
result_data[script_dir]="$SCRIPT_DIR"
result_data[manual_test_status]="not_run"
result_data[scoring_status]="not_run"
result_data[overall_status]="running"

# Function to send results to the endpoint
send_results() {
    local status="$1"
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    # Build JSON payload
    local json_payload=$(cat <<EOF
{
    "test_id": "${result_data[test_id]}",
    "start_time": "${result_data[start_time]}",
    "end_time": "$(date -d @$end_time -Iseconds)",
    "duration_seconds": $duration,
    "script_dir": "${result_data[script_dir]}",
    "manual_test_status": "${result_data[manual_test_status]}",
    "manual_test_exit_code": ${result_data[manual_test_exit_code]:-"null"},
    "scoring_status": "${result_data[scoring_status]}",
    "scoring_Okay,  good. Nexit_code": ${result_data[scoring_exit_code]:-"null"},
    "overall_status": "$status",
    "final_exit_code": ${result_data[final_exit_code]:-"null"},
    "errors": [${result_data[errors]:-""}],
    "hostname": "$(hostname)",
    "user": "$(whoami)"
}
EOF
)

    echo "📤 Sending results to $RESULT_ENDPOINT..."
    
    # Send POST request with curl
    if command -v curl >/dev/null 2>&1; then
        curl_response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            "$RESULT_ENDPOINT" 2>/dev/null)
        
        http_status=$(echo "$curl_response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
        response_body=$(echo "$curl_response" | sed 's/HTTP_STATUS:[0-9]*$//')
        
        if [[ "$http_status" =~ ^2[0-9][0-9]$ ]]; then
            echo "✅ Results sent successfully (HTTP $http_status)"
        else
            echo "⚠️  Warning: Failed to send results (HTTP $http_status)"
            echo "Response: $response_body"
        fi
    else
        echo "⚠️  Warning: curl not available, cannot send results to endpoint"
    fi
}

# Function to add error to results
add_error() {
    local error_msg="$1"
    if [[ -n "${result_data[errors]}" ]]; then
        result_data[errors]="${result_data[errors]}, \"$error_msg\""
    else
        result_data[errors]="\"$error_msg\""
    fi
}

# Trap to ensure results are sent even if script is interrupted
trap 'send_results "interrupted"; exit 1' INT TERM

# 🔹 Check and run manual testing script
if [[ -x "$MANUAL_SCRIPT" ]]; then
    echo "🚀 Running manual chaos tests..."
    "$MANUAL_SCRIPT"
    manual_test_status=$?
    
    result_data[manual_test_status]="completed"
    result_data[manual_test_exit_code]="$manual_test_status"
    
    if [[ $manual_test_status -ne 0 ]]; then
        add_error "Manual test script failed with exit code $manual_test_status"
        echo "⚠️  Manual test script completed with exit code: $manual_test_status"
    else
        echo "✅ Manual test script completed successfully"
    fi
else
    result_data[manual_test_status]="failed"
    add_error "Manual test script not found or not executable at $MANUAL_SCRIPT"
    echo "❌ Error: Manual test script not found or not executable at $MANUAL_SCRIPT"
    send_results "failed"
    exit 1
fi

# 🔹 Check and run scoring script
if [[ -x "$SCORING_SCRIPT" ]]; then
    echo -e "\n📊 Running chaos test analysis..."
    "$SCORING_SCRIPT"
    final_status=$?
    
    result_data[scoring_status]="completed"
    result_data[scoring_exit_code]="$final_status"
    result_data[final_exit_code]="$final_status"
    
    if [[ $final_status -ne 0 ]]; then
        add_error "Scoring script failed with exit code $final_status"
        echo "⚠️  Scoring script completed with exit code: $final_status"
        send_results "failed"
    else
        echo "✅ Scoring script completed successfully"
        send_results "success"
    fi
else
    result_data[scoring_status]="failed"
    result_data[final_exit_code]="1"
    add_error "Scoring script not found or not executable at $SCORING_SCRIPT"
    echo "❌ Error: Scoring script not found or not executable at $SCORING_SCRIPT"
    send_results "failed"
    exit 1
fi

echo -e "\n🎉 Chaos testing sequence completed!"
echo "📋 Test ID: ${result_data[test_id]}"
echo "⏱️  Duration: $(($(date +%s) - START_TIME)) seconds"

# 🔚 Exit with the status from scoring script
exit $final_status