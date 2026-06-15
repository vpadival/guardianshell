#!/bin/bash

# ==============================================================================
# GuardianShell System Monitor Sub-Script
# Handles Disk, CPU, and Memory Thrashing checks.
# ==============================================================================

# Sourcing or fallback to environment defaults
MAX_DISK=${MAX_DISK:-80}
MAX_CPU=${MAX_CPU:-90}
THRASH_LIMIT=${THRASH_LIMIT:-100}
LOG_FILE=${LOG_FILE:-"/home/vachan/Documents/guardianshell/logs/system_monitor.log"}
MAX_AUTH_FAILURES=${MAX_AUTH_FAILURES:-5}
AUTH_LOG=${AUTH_LOG:-"/var/log/auth.log"}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Ordinary local variables for status tracking
status_ok=true
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

echo "============================================="
echo "        GuardianShell System Monitor         "
echo "============================================="
echo "Checked at: $timestamp"
echo "---------------------------------------------"

# --- 1. Disk Usage Check ---
# Parse root filesystem usage percentage
disk_usage=$(df -h / | tail -n 1 | awk '{print $5}' | tr -d '%')

# Verify numeric conversion
if [[ "$disk_usage" =~ ^[0-9]+$ ]]; then
    echo "Disk Usage: ${disk_usage}% (Threshold: ${MAX_DISK}%)"
    
    # Use if statement with test [ ] to check threshold
    if [ "$disk_usage" -gt "$MAX_DISK" ]; then
        status_ok=false
        
        # User warning printed to stderr (FD 2)
        echo "⚠️  CRITICAL: Disk usage has exceeded the safe threshold of ${MAX_DISK}%!" >&2
        
        # Log entry written to logs/system_monitor.log using output redirection (>>)
        echo "[$timestamp] [CRITICAL] Disk usage is at ${disk_usage}%, exceeding the threshold of ${MAX_DISK}%!" >> "$LOG_FILE"
    else
        echo "✅ Disk usage is within safe limits."
    fi
else
    echo "❌ Error: Failed to parse disk usage." >&2
    status_ok=false
fi

echo "---------------------------------------------"

# --- 2. Memory Thrashing & CPU Swapping Check ---
# Parse vmstat 1 2 (second line represents current system metrics)
vmstat_out=$(vmstat 1 2 2>/dev/null | tail -n 1)

if [ -n "$vmstat_out" ]; then
    # Columns: si (swap-in rate) is 7th, so (swap-out rate) is 8th, id (cpu idle) is 15th
    swap_in=$(echo "$vmstat_out" | awk '{print $7}')
    swap_out=$(echo "$vmstat_out" | awk '{print $8}')
    cpu_idle=$(echo "$vmstat_out" | awk '{print $15}')
    
    # Validate parsed variables
    if [[ ! "$swap_in" =~ ^[0-9]+$ ]]; then swap_in=0; fi
    if [[ ! "$swap_out" =~ ^[0-9]+$ ]]; then swap_out=0; fi
    if [[ ! "$cpu_idle" =~ ^[0-9]+$ ]]; then cpu_idle=100; fi
    
    cpu_usage=$((100 - cpu_idle))
    
    echo "Swapping Activity:"
    echo "  - Swap-In (si)  : ${swap_in} KB/s"
    echo "  - Swap-Out (so) : ${swap_out} KB/s"
    echo "  - Thrash Limit  : ${THRASH_LIMIT} KB/s"
    
    # Check if swap rates indicate Memory Thrashing
    if [ "$swap_in" -gt "$THRASH_LIMIT" ] || [ "$swap_out" -gt "$THRASH_LIMIT" ]; then
        status_ok=false
        
        # User warning printed to stderr (FD 2)
        echo "⚠️  WARNING: High swapping activity detected! System may be thrashing." >&2
        
        # Log entry written to logs/system_monitor.log using output redirection (>>)
        echo "[$timestamp] [WARNING] Swapping exceeded thrashing limit of ${THRASH_LIMIT} KB/s! (si: ${swap_in} KB/s, so: ${swap_out} KB/s)" >> "$LOG_FILE"
    else
        echo "✅ Swapping activity is within normal range."
    fi
    
    echo "---------------------------------------------"
    echo "CPU Usage: ${cpu_usage}% (Threshold: ${MAX_CPU}%)"
    
    # Check CPU usage threshold
    if [ "$cpu_usage" -gt "$MAX_CPU" ]; then
        status_ok=false
        
        # User warning printed to stderr (FD 2)
        echo "⚠️  WARNING: High CPU utilization!" >&2
        
        # Log entry written to logs/system_monitor.log using output redirection (>>)
        echo "[$timestamp] [WARNING] CPU usage is at ${cpu_usage}%, exceeding the threshold of ${MAX_CPU}%!" >> "$LOG_FILE"
    else
        echo "✅ CPU usage is within safe limits."
    fi
else
    echo "⚠️  Warning: Could not fetch swap/CPU metrics via vmstat."
fi

echo "---------------------------------------------"
echo "Security Authentication Check:"

if [ -r "$AUTH_LOG" ]; then
    # Scan last 100 lines for authentication failure patterns using grep -E
    auth_failures=$(tail -n 100 "$AUTH_LOG" | grep -Ei "(fail|invalid user|refused password|unauthorized|failed password)" | wc -l)
    
    echo "  - Log Checked   : $AUTH_LOG (last 100 entries)"
    echo "  - Failure Count : $auth_failures (Threshold: $MAX_AUTH_FAILURES)"
    
    if [ "$auth_failures" -gt "$MAX_AUTH_FAILURES" ]; then
        status_ok=false
        echo "⚠️  WARNING: High number of authentication failures detected!" >&2
        echo "[$timestamp] [WARNING] Security Alert: $auth_failures authentication failures detected in $AUTH_LOG (Threshold: $MAX_AUTH_FAILURES)!" >> "$LOG_FILE"
    else
        echo "✅ Authentication activity is within safe parameters."
    fi
else
    echo "⚠️  Warning: Security log $AUTH_LOG is not readable or does not exist."
fi

echo "---------------------------------------------"
echo "System Uptime: $(uptime -p)"
echo "============================================="

# Return exit status indicating overall status (0 if all OK, 1 if any thresholds exceeded)
if [ "$status_ok" = true ]; then
    exit 0
else
    exit 1
fi
