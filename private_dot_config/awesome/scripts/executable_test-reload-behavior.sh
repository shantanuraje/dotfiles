#!/usr/bin/env bash

# Test AwesomeWM Reload Behavior
# Validates that applications don't duplicate on reload

echo "=== AwesomeWM Reload Test ==="
echo "This script tests that applications don't duplicate when AwesomeWM is reloaded"
echo

# Define applications to monitor
APPS=(
    "chrome"
    "obsidian" 
    "claude-desktop"
    "kitty.*dev1"
    "kitty.*dev2"
    "code"
    "insync"
    "discord"
    "synergy"
)

# Function to count running processes
count_processes() {
    local pattern="$1"
    pgrep -f -c "$pattern" 2>/dev/null || echo "0"
}

# Function to show process status
show_status() {
    echo "Current application status:"
    for app in "${APPS[@]}"; do
        local count=$(count_processes "$app")
        printf "  %-15s: %d instances\n" "$app" "$count"
    done
    echo
}

# Main test function
test_reload() {
    echo "Step 1: Recording initial state..."
    declare -A initial_counts
    for app in "${APPS[@]}"; do
        initial_counts[$app]=$(count_processes "$app")
    done
    show_status
    
    echo "Step 2: Reloading AwesomeWM..."
    echo "Please reload AwesomeWM now with Mod+Ctrl+r"
    echo "Press Enter after reloading..."
    read
    
    echo "Step 3: Waiting for reload to complete..."
    sleep 3
    
    echo "Step 4: Checking for duplicates..."
    declare -A final_counts
    local duplicates_found=false
    
    for app in "${APPS[@]}"; do
        final_counts[$app]=$(count_processes "$app")
        local initial=${initial_counts[$app]}
        local final=${final_counts[$app]}
        
        if [[ $final -gt $initial ]]; then
            echo "❌ DUPLICATE DETECTED: $app increased from $initial to $final"
            duplicates_found=true
        else
            echo "✅ OK: $app remained at $final instances"
        fi
    done
    
    echo
    show_status
    
    if [[ "$duplicates_found" == "true" ]]; then
        echo "❌ TEST FAILED: Application duplicates detected!"
        echo "The reload protection is not working correctly."
        return 1
    else
        echo "✅ TEST PASSED: No application duplicates found!"
        echo "Reload protection is working correctly."
        return 0
    fi
}

# Interactive mode
echo "This test will help verify that AwesomeWM reload doesn't duplicate applications."
echo "Make sure you have some applications running first."
echo
echo "Options:"
echo "1. Run automatic test (requires manual reload)"
echo "2. Show current status only"
echo "3. Manual process counting"
echo
read -p "Choose option (1-3): " choice

case $choice in
    1)
        test_reload
        ;;
    2)
        show_status
        ;;
    3)
        echo "Manual testing mode:"
        echo "1. Run 'show_status' to see current state"
        echo "2. Reload AwesomeWM with Mod+Ctrl+r"
        echo "3. Run 'show_status' again to compare"
        echo
        while true; do
            read -p "Enter command (show_status/exit): " cmd
            case $cmd in
                show_status)
                    show_status
                    ;;
                exit)
                    break
                    ;;
                *)
                    echo "Unknown command: $cmd"
                    ;;
            esac
        done
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "Test completed."