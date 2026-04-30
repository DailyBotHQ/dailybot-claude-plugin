#!/bin/bash
# Dailybot SessionEnd cleanup.
# Removes per-session state files. Always silent. Always exits 0.
# Set DAILYBOT_DEBUG=1 to preserve the .log file for inspection.

set -u

STORAGE_ROOT="${CLAUDE_PLUGIN_DATA:-$HOME/.dailybot-claude/sessions}"
[ -d "$STORAGE_ROOT" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
[ -z "$SESSION_ID" ] && exit 0
case "$SESSION_ID" in
  *[!A-Za-z0-9._-]*) exit 0 ;;
esac

rm -f "$STORAGE_ROOT/dailybot-${SESSION_ID}.reported" 2>/dev/null
rm -f "$STORAGE_ROOT/dailybot-${SESSION_ID}.last-fired" 2>/dev/null

if [ "${DAILYBOT_DEBUG:-0}" != "1" ]; then
  rm -f "$STORAGE_ROOT/dailybot-${SESSION_ID}.log" 2>/dev/null
fi

exit 0
