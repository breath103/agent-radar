#!/bin/bash
set -e

echo "=== Window Move Test ==="

# Get current window position
get_window_pos() {
    osascript -e '
    tell application "System Events"
        tell process "AgentRadar"
            set {x, y} to position of window 1
            return (x as text) & "," & (y as text)
        end tell
    end tell' 2>/dev/null || echo "no window"
}

echo "Window before: $(get_window_pos)"

# Move window far to the right (simulate different screen)
osascript -e '
tell application "System Events"
    tell process "AgentRadar"
        set position of window 1 to {3000, 100}
    end tell
end tell'

sleep 0.5
echo "Window moved to: $(get_window_pos)"

# Send notification (mouse cursor should be on this screen where terminal is)
scripts/send-test-notification.sh /tmp/window-move-test Stop
sleep 2

POS_AFTER=$(get_window_pos)
echo "Window after notification: $POS_AFTER"

# Check: x coordinate should be < 3000 if it moved back
X_AFTER=$(echo "$POS_AFTER" | cut -d',' -f1)
if [ "$X_AFTER" -lt 2000 ] 2>/dev/null; then
    echo "PASS: Window moved back to current screen (x=$X_AFTER)"
else
    echo "FAIL: Window stayed at x=$X_AFTER"
fi
