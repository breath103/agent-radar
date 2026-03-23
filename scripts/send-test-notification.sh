#!/bin/bash
PWD_PATH="${1:-/tmp/test-project}"
EVENT="${2:-Stop}"
PID="${3:-1111}"

NOTIFY_DIR="$HOME/.agent-radar/notifications"
mkdir -p "$NOTIFY_DIR"
echo "{\"pwd\":\"$PWD_PATH\",\"hook_event\":\"$EVENT\",\"shell_pid\":$PID,\"timestamp\":$(date +%s)}" > "$NOTIFY_DIR/$(date +%s)-$$.json"
echo "Sent $EVENT notification for $PWD_PATH"
