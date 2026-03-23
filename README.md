# AgentRadar

Native macOS app for managing multiple Claude Code agentic coding sessions. Each session's notifications appear as a column with quick actions to jump to the terminal or IDE.

## Install

```bash
# Build and install to /Applications
scripts/build.sh
```

## Setup

### 1. Hook configuration

Add the following to the top of your Claude Code hook script (e.g. `~/.claude/scripts/on-stop.sh`):

```bash
SHELL_PID=$(ps -o ppid= -p $PPID | tr -d ' ')
NOTIFY_DIR="$HOME/.agent-radar/notifications"
mkdir -p "$NOTIFY_DIR"
cat > "$NOTIFY_DIR/$(date +%s)-$$.json" <<EOF
{"pwd":"$(pwd)","hook_event":"${CLAUDE_HOOK_EVENT:-Stop}","shell_pid":$SHELL_PID,"timestamp":$(date +%s)}
EOF
```

### 2. Claude settings.json

Make sure your `~/.claude/settings.json` has hooks for both `Stop` and `Notification` events pointing to your hook script:

```json
{
  "hooks": {
    "Stop": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/scripts/on-stop.sh" }] }],
    "Notification": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/scripts/on-stop.sh" }] }]
  }
}
```

### 3. Ghostty terminal focusing

The "Go to Terminal" button uses Ghostty's AppleScript API. It reads cached window/tab IDs from `/tmp/ghostty-claude-{pid}` which are created by the existing hook script.

## How it works

- Hook script writes JSON files to `~/.agent-radar/notifications/`
- App polls the directory every second
- Each unique `pwd` becomes a project column
- Columns show notification history with timestamps
- "Terminal" button focuses the Ghostty tab running that session
- "VSCode" button opens the project in VS Code

## Scripts

- `scripts/build.sh` - Debug build, install to /Applications, launch
- `scripts/build-release.sh` - Release build
- `scripts/test-e2e.sh` - E2E test using Accessibility API
- `scripts/screenshot.sh` - Screenshot the app

## Test

```bash
# Send a test notification
mkdir -p ~/.agent-radar/notifications
echo '{"pwd":"/tmp/test","hook_event":"Stop","shell_pid":1234,"timestamp":'$(date +%s)'}' > ~/.agent-radar/notifications/test.json
```
