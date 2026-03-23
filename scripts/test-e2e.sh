#!/bin/bash
set -e

NOTIFY_DIR="$HOME/.agent-radar/notifications"
mkdir -p "$NOTIFY_DIR"

# Clean any leftover files
rm -f "$NOTIFY_DIR"/*.json

# Wait a moment for the watcher to settle after cleanup
sleep 0.5

# Send test notifications for two different projects
cat > "$NOTIFY_DIR/test1-$$.json" <<EOF
{"pwd":"/Users/test/Work/project-alpha","hook_event":"Stop","shell_pid":1111,"timestamp":$(date +%s)}
EOF

sleep 0.5

cat > "$NOTIFY_DIR/test2-$$.json" <<EOF
{"pwd":"/Users/test/Work/project-beta","hook_event":"Notification","shell_pid":2222,"timestamp":$(date +%s)}
EOF

sleep 2

# Read UI via Accessibility API
echo "=== AgentRadar UI State ==="
osascript -e '
tell application "System Events"
    tell process "AgentRadar"
        set output to ""
        try
            set w to window 1
            set output to output & "Window: " & (name of w) & linefeed
            set allElements to entire contents of w
            repeat with el in allElements
                try
                    set elRole to role of el
                    set elValue to value of el
                    if elValue is not missing value and elValue is not "" then
                        set output to output & elRole & ": " & elValue & linefeed
                    end if
                end try
            end repeat
        end try
        return output
    end tell
end tell'
echo "=== Done ==="

# Verify expected content
RESULT=$(osascript -e '
tell application "System Events"
    tell process "AgentRadar"
        set output to ""
        set allElements to entire contents of window 1
        repeat with el in allElements
            try
                set v to value of el
                if v is not missing value then set output to output & v & "|"
            end try
        end repeat
        return output
    end tell
end tell')

PASS=0
FAIL=0

check() {
    if echo "$RESULT" | grep -q "$1"; then
        echo "PASS: found '$1'"
        PASS=$((PASS + 1))
    else
        echo "FAIL: missing '$1'"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "=== Assertions ==="
check "project-alpha"
check "project-beta"
check "Stop"
check "Notification"
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
