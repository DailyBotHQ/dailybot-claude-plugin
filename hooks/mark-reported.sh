#!/bin/bash
# Dailybot mark-reported hook (PostToolUse — Bash only)
# Detects successful report commands and creates the .reported flag
# so the Stop gate does not re-nudge for this session.
# Never produces stdout. Never blocks. Always exits 0.

set -u

STORAGE_ROOT="${CLAUDE_PLUGIN_DATA:-$HOME/.dailybot-claude/sessions}"
mkdir -p "$STORAGE_ROOT" 2>/dev/null || exit 0

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
[ -z "$SESSION_ID" ] || [ "$TOOL_NAME" != "Bash" ] && exit 0

case "$SESSION_ID" in
  *[!A-Za-z0-9._-]*) exit 0 ;;
esac

COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$COMMAND" ] && exit 0

# Match CLI report path or HTTP fallback path.
IS_REPORT="false"
case "$COMMAND" in
  *"dailybot agent update"*) IS_REPORT="true" ;;
  *"/v1/agent-reports/"*)     IS_REPORT="true" ;;
esac
[ "$IS_REPORT" = "false" ] && exit 0

# Defensive: skip if the tool response suggests failure.
RESPONSE="$(printf '%s' "$INPUT" | jq -r '.tool_response // empty' 2>/dev/null)"
case "$RESPONSE" in
  *"error"*|*"Error"*|*"failed"*|*"Failed"*|*"command not found"*) exit 0 ;;
esac

touch "$STORAGE_ROOT/dailybot-${SESSION_ID}.reported" 2>/dev/null

exit 0
