#!/bin/bash
# lf Cleaner Script - Clean up preview artifacts
# Handles cleanup for image previews and temporary files

# Clean up any temporary files created during preview
rm -f /tmp/lf_thumb_* 2>/dev/null

# Clear any remaining image previews (for terminal image protocols)
if [ -n "$KITTY_WINDOW_ID" ]; then
    # Clear Kitty graphics protocol images
    printf '\33_Ga=d\33\\'
fi

# Clear any w3m image cache if used
if [ -d /tmp/w3m* ]; then
    rm -rf /tmp/w3m* 2>/dev/null
fi