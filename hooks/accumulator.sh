#!/bin/bash
# Dailybot accumulator hook (PostToolUse)
# Silently logs meaningful tool uses to a per-session file.
# Never produces stdout. Never blocks. Always exits 0.

set -u

STORAGE_ROOT="${CLAUDE_PLUGIN_DATA:-$HOME/.dailybot-claude/sessions}"
mkdir -p "$STORAGE_ROOT" 2>/dev/null || exit 0

# 7-day retention sweep — fire-and-forget.
find "$STORAGE_ROOT" -maxdepth 1 -type f \( -name 'dailybot-*.log' -o -name 'dailybot-*.reported' -o -name 'dailybot-*.last-fired' \) -mtime +7 -delete 2>/dev/null

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
[ -z "$SESSION_ID" ] || [ -z "$TOOL_NAME" ] && exit 0

# Sanitize session_id to filename-safe chars only.
case "$SESSION_ID" in
  *[!A-Za-z0-9._-]*) exit 0 ;;
esac

LOG_FILE="$STORAGE_ROOT/dailybot-${SESSION_ID}.log"

# Extract a short summary depending on the tool.
SUMMARY=""
case "$TOOL_NAME" in
  Edit|Write|MultiEdit)
    SUMMARY="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
    ;;
  Bash)
    SUMMARY="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null | head -c 120 | tr '\n\t' '  ')"
    ;;
  *)
    exit 0
    ;;
esac

[ -z "$SUMMARY" ] && exit 0

# Filter trivial paths for file-edit tools.
# Strict matching: exact extension at end of basename, or directory prefix anywhere in path.
if [ "$TOOL_NAME" != "Bash" ]; then
  BASENAME="${SUMMARY##*/}"
  case "$BASENAME" in
    *.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|Pipfile.lock|poetry.lock|Cargo.lock|Gemfile.lock|composer.lock|go.sum) exit 0 ;;
    *.log) exit 0 ;;
  esac
  case "/$SUMMARY/" in
    */node_modules/*|*/dist/*|*/.git/*|*/.next/*|*/build/*|*/target/*|*/__pycache__/*|*/.venv/*|*/venv/*|*/.cache/*) exit 0 ;;
  esac
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '%s\t%s\t%s\n' "$TS" "$TOOL_NAME" "$SUMMARY" >> "$LOG_FILE" 2>/dev/null

exit 0
