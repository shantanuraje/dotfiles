#!/usr/bin/env bash

# Safe Launch Script for AwesomeWM
# Prevents duplicate application launches by checking if process already exists
# Usage: safe-launch.sh <process_pattern> <command>

PROCESS_PATTERN="$1"
COMMAND="$2"
TIMEOUT=5

# Validate arguments
if [[ -z "$PROCESS_PATTERN" || -z "$COMMAND" ]]; then
    echo "Usage: $0 <process_pattern> <command>"
    echo "Example: $0 'chrome' 'google-chrome-stable'"
    exit 1
fi

# Function to check if process is running
is_process_running() {
    local pattern="$1"
    # Use pgrep with full command line matching and current user only
    pgrep -f -u "$USER" "$pattern" > /dev/null 2>&1
    return $?
}

# Function to launch application safely
safe_launch() {
    local pattern="$1"
    local cmd="$2"
    
    echo "Checking for existing process: $pattern"
    
    if is_process_running "$pattern"; then
        echo "Process '$pattern' already running, skipping launch"
        return 0
    else
        echo "Launching: $cmd"
        # Launch in background and detach from shell
        nohup bash -c "$cmd" > /dev/null 2>&1 &
        disown
        
        # Brief wait to allow process to start
        sleep 1
        
        # Verify launch was successful
        local retry_count=0
        while [[ $retry_count -lt $TIMEOUT ]]; do
            if is_process_running "$pattern"; then
                echo "Successfully launched: $cmd"
                return 0
            fi
            sleep 1
            ((retry_count++))
        done
        
        echo "Warning: Failed to detect launched process '$pattern' after $TIMEOUT seconds"
        return 1
    fi
}

# Main execution
safe_launch "$PROCESS_PATTERN" "$COMMAND"