#!/bin/bash

# Notify AgentRadar (skip if Ghostty is frontmost)
FRONT_BUNDLE=$(osascript -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null)
if [ "$FRONT_BUNDLE" != "com.mitchellh.ghostty" ]; then
    SHELL_PID=$(ps -o ppid= -p $PPID | tr -d ' ')
    NOTIFY_DIR="$HOME/.agent-radar/notifications"
    mkdir -p "$NOTIFY_DIR"
    cat > "$NOTIFY_DIR/$(date +%s)-$$.json" <<EOF
{"pwd":"$(pwd)","hook_event":"${CLAUDE_HOOK_EVENT:-Stop}","shell_pid":$SHELL_PID,"timestamp":$(date +%s)}
EOF
fi
