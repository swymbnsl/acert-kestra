#!/bin/bash
# chaos-monitor.sh

APP_LABEL="app=sample-microservice"
APP_URL="http://127.0.0.1:32819"
DURATION=360  # 6 minutes
INTERVAL=5    # 5 seconds
CURL_TIMEOUT=10  # 10 seconds timeout for curl

echo "🔍 Starting Chaos Monitoring for $DURATION seconds"
echo "=================================================="

# Create results file
RESULTS_FILE="chaos-test-results-$(date +%Y%m%d-%H%M%S).txt"
echo "Timestamp,HTTP_Status,Response_Time,Pod_Count,CPU_Usage,Memory_Usage" > $RESULTS_FILE

for ((i=1; i<=DURATION/INTERVAL; i++)); do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Test application response with proper timeout
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" --max-time $CURL_TIMEOUT $APP_URL 2>/dev/null || echo "000,0")
    HTTP_STATUS=$(echo $RESPONSE | cut -d',' -f1)
    RESPONSE_TIME=$(echo $RESPONSE | cut -d',' -f2)
    
    # Get only RUNNING pods count
    POD_COUNT=$(kubectl get pods -l $APP_LABEL --no-headers 2>/dev/null | grep "Running" | wc -l)
    
    # Get resource usage with proper error handling
    RESOURCES=$(kubectl top pods -l $APP_LABEL --no-headers 2>/dev/null | awk '
        BEGIN {cpu=0; mem=0; count=0}
        {
            cpu+=$2; 
            mem+=$3; 
            count++
        } 
        END {
            if(count>0) printf "%.1f,%.1f", cpu/count, mem/count
            else print "0,0"
        }
    ')
    
    # Log results
    echo "$TIMESTAMP,$HTTP_STATUS,$RESPONSE_TIME,$POD_COUNT,$RESOURCES" >> $RESULTS_FILE
    
    # Display current status
    printf "⏱️  %s | Status: %s | Time: %.3fs | Running Pods: %d\n" "$TIMESTAMP" "$HTTP_STATUS" "$RESPONSE_TIME" "$POD_COUNT"
    
    sleep $INTERVAL
done

echo "✅ Monitoring complete. Results saved to $RESULTS_FILE"