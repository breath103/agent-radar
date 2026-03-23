#!/bin/bash
set -e

echo "=== Window Move Test ==="

# Move window to screen 1 (left screen) via special command
# shell_pid=1 means screen index 1
scripts/send-test-notification.sh unused _move_to_screen 1
sleep 2

echo "After moving to screen 1:"
cat /tmp/agent-radar-move.log 2>/dev/null && echo "(old log)" || echo "no log"

# Now send a real notification - window should move back to mouse (screen 0)
rm -f /tmp/agent-radar-move.log
scripts/send-test-notification.sh /tmp/move-back-test Stop
sleep 2

echo ""
echo "After notification (should move to mouse screen):"
cat /tmp/agent-radar-move.log 2>/dev/null || echo "no log - moveWindowToCurrentScreen didn't run"

echo ""
# Check if mouse and window are on different screens in the log
if grep -q "mouseScreen.*windowScreen" /tmp/agent-radar-move.log 2>/dev/null; then
    MOUSE_SCREEN=$(grep -o 'mouseScreen=([^)]*' /tmp/agent-radar-move.log | head -1)
    WINDOW_SCREEN=$(grep -o 'windowScreen=([^)]*' /tmp/agent-radar-move.log | head -1)
    OLD_FRAME=$(grep -o 'oldFrame=([^)]*' /tmp/agent-radar-move.log | head -1)
    NEW_FRAME=$(grep -o 'newFrame=([^)]*' /tmp/agent-radar-move.log | head -1)

    echo "Mouse screen: $MOUSE_SCREEN"
    echo "Window screen: $WINDOW_SCREEN"
    echo "Old frame: $OLD_FRAME"
    echo "New frame: $NEW_FRAME"

    if [ "$OLD_FRAME" != "$NEW_FRAME" ]; then
        echo "PASS: Window moved to different position"
    else
        echo "FAIL: Window frame unchanged"
    fi
else
    echo "FAIL: Could not parse log"
fi
