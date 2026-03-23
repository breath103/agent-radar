#!/bin/bash
set -e

NOTIFY_DIR="$HOME/.agent-radar/notifications"
mkdir -p "$NOTIFY_DIR"
rm -f "$NOTIFY_DIR"/*.json

osascript -e 'quit app "AgentRadar"' 2>/dev/null || true
sleep 0.5
open /Applications/AgentRadar.app
sleep 2

# Send both notifications
cat > "$NOTIFY_DIR/test1-$$.json" <<EOF
{"pwd":"/Users/test/Work/project-alpha","hook_event":"Stop","shell_pid":1111,"timestamp":$(date +%s)}
EOF
cat > "$NOTIFY_DIR/test2-$$.json" <<EOF
{"pwd":"/Users/test/Work/project-beta","hook_event":"Notification","shell_pid":2222,"timestamp":$(date +%s)}
EOF

sleep 2

read_ui() {
    osascript -e '
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
    end tell'
}

press_button() {
    osascript -e "
    tell application \"System Events\"
        tell process \"AgentRadar\"
            set allElements to entire contents of window 1
            repeat with el in allElements
                try
                    if role of el is \"AXButton\" then
                        set ident to value of attribute \"AXIdentifier\" of el
                        if ident is \"$1\" then
                            perform action \"AXPress\" of el
                            return \"pressed\"
                        end if
                    end if
                end try
            end repeat
            return \"not found\"
        end tell
    end tell"
}

PASS=0
FAIL=0

check() {
    if echo "$1" | grep -q "$2"; then
        echo "  PASS: found '$2'"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: missing '$2'"
        FAIL=$((FAIL + 1))
    fi
}

check_absent() {
    if echo "$1" | grep -q "$2"; then
        echo "  FAIL: '$2' still present"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: '$2' removed"
        PASS=$((PASS + 1))
    fi
}

# Test 1: Notifications appear
echo "=== Test 1: Notifications appear ==="
RESULT=$(read_ui)
check "$RESULT" "project-alpha"
check "$RESULT" "project-beta"
check "$RESULT" "|Stop|"
check "$RESULT" "|Notification|"

# Test 2: Clear
echo ""
echo "=== Test 2: Clear button ==="
CLICK=$(press_button "clear")
echo "  click: $CLICK"
sleep 1
RESULT=$(read_ui)
check "$RESULT" "project-alpha"
check "$RESULT" "No notifications"

# Test 3: Remove (only one project left with notifications: project-beta)
# The first "remove" button in tree order is now project-alpha (cleared), remove it
echo ""
echo "=== Test 3: Remove button ==="
CLICK=$(press_button "remove")
echo "  click: $CLICK"
sleep 1
RESULT=$(read_ui)
# Exactly one project should remain
ALPHA=$(echo "$RESULT" | grep -c "project-alpha" || true)
BETA=$(echo "$RESULT" | grep -c "project-beta" || true)
TOTAL=$((ALPHA + BETA))
if [ "$TOTAL" -eq 1 ]; then
    echo "  PASS: one project removed, one remains"
    PASS=$((PASS + 1))
else
    echo "  FAIL: expected 1 project, found $TOTAL"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
