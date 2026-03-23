# AgentRadar

Native macOS menu bar app for managing multiple Claude Code agentic coding sessions. Each session's notifications appear as a column with quick actions to jump to the terminal or IDE.

## Install

```bash
# Build and install to /Applications
scripts/build.sh

# Install hook script
scripts/install-hooks.sh
```

## Setup

### Hook configuration

Run `scripts/install-hooks.sh` to copy the hook script to `~/.claude/scripts/agent-radar-hook.sh`.

Then add the following to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/scripts/agent-radar-hook.sh" }] }],
    "Notification": [{ "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/scripts/agent-radar-hook.sh" }] }]
  }
}
```

The hook script skips notifications when Ghostty is the frontmost app (since you're already looking at the terminal).

## Keyboard Shortcuts

- `Cmd+Shift+R` - Toggle panel (global, works even when app is not focused)
- `Cmd+Shift+L` - Jump to terminal of most recently active project and close panel

## How it works

- Hook script writes JSON files to `~/.agent-radar/notifications/`
- App polls the directory every second
- Each unique `pwd` becomes a project column
- Columns show notification history with timestamps
- "Terminal" button focuses the Ghostty tab, clears notifications, and closes panel
- "VSCode" button opens the project in VS Code

## Scripts

- `scripts/build.sh` - Debug build, install to /Applications, launch
- `scripts/build-release.sh` - Release build
- `scripts/install-hooks.sh` - Install hook script to ~/.claude/scripts/
- `scripts/test-e2e.sh` - E2E test using Accessibility API
- `scripts/send-test-notification.sh` - Send a test notification
