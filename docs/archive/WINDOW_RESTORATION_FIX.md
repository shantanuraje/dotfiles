# Window Restoration Fix Documentation

## Problem Identified
After clicking on a window in the window manager menu, the system would switch to the correct workspace but the window would remain minimized instead of being restored and focused.

## Root Cause
The original window restoration function was attempting to:
1. Switch workspace and restore window in a single awesome-client call
2. This caused a race condition where the window restoration happened before the workspace switch was fully completed

## Solution Implemented

### Two-Step Restoration Process
```bash
# Function to restore window
restore_window() {
    local workspace=$1
    local window_index=$2
    
    # Step 1: Switch to the workspace
    echo "require('awful').screen.focused().tags[$workspace]:view_only()" | awesome-client >/dev/null 2>&1
    
    # Step 2: Small delay to ensure workspace switch completes
    sleep 0.1
    
    # Step 3: Restore the window on the now-current workspace
    echo "
    local tag = require('awful').screen.focused().selected_tag
    if tag then
        local client = tag:clients()[$window_index]
        if client then
            client.minimized = false
            client:raise()
            require('awful').client.focus.byidx(0, client)
        end
    end
    " | awesome-client >/dev/null 2>&1
}
```

### Key Changes
1. **Separated Operations**: Split workspace switching and window restoration into separate awesome-client calls
2. **Added Timing**: 0.1 second delay ensures workspace switch completes before window restoration
3. **Consistent Pattern**: Uses the same restoration pattern as the working window-menu script
4. **Applied to Multiple Scripts**: Updated both `window-manager.sh` and `awesome-workspaces.sh` for consistency

## Files Modified
- `executable_window-manager.sh` - Fixed main window restoration function
- `executable_awesome-workspaces.sh` - Fixed workspace-specific window restoration

## Testing
The fix ensures that:
- ✅ Clicking on a window in the menu switches to the correct workspace
- ✅ The window is properly restored (unminimized)
- ✅ The window receives focus
- ✅ Works consistently across all window management interfaces

## Technical Details
The fix addresses the asynchronous nature of workspace switching in Awesome WM by:
1. Using separate awesome-client calls for workspace switching and window restoration
2. Adding a small delay to ensure operations complete in the correct order
3. Using the `selected_tag` approach which works reliably on the current workspace

This resolves the race condition that was causing windows to remain minimized after workspace switching.
