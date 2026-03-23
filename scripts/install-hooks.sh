#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SOURCE="$SCRIPT_DIR/on-stop.sh"
HOOK_DEST="$HOME/.claude/scripts/agent-radar-hook.sh"

mkdir -p "$HOME/.claude/scripts"
cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

echo "Installed hook to $HOOK_DEST"
echo ""
echo "Add the following to your ~/.claude/settings.json:"
echo ""
cat <<'SETTINGS'
{
  "hooks": {
    "Stop": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/scripts/agent-radar-hook.sh" }] }],
    "Notification": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/scripts/agent-radar-hook.sh" }] }]
  }
}
SETTINGS
