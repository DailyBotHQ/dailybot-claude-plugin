#!/bin/bash
# Dailybot Stop-hook gate.
# Deterministic preconditions filter cheap turns; only emits exactly one
# validated JSON object on stdout when a nudge is warranted.
# Any failure path → exit 0 with no stdout.

set -u

STORAGE_ROOT="${CLAUDE_PLUGIN_DATA:-$HOME/.dailybot-claude/sessions}"
mkdir -p "$STORAGE_ROOT" 2>/dev/null || exit 0

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)"
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
[ -z "$SESSION_ID" ] && exit 0
case "$SESSION_ID" in
  *[!A-Za-z0-9._-]*) exit 0 ;;
esac

LOG_FILE="$STORAGE_ROOT/dailybot-${SESSION_ID}.log"
REPORTED_FLAG="$STORAGE_ROOT/dailybot-${SESSION_ID}.reported"
LAST_FIRED="$STORAGE_ROOT/dailybot-${SESSION_ID}.last-fired"

# Guard 1: already reported this session.
[ -f "$REPORTED_FLAG" ] && exit 0

# Guard 2: rate-limit gate re-firing — no more than once per 60s per session.
if [ -f "$LAST_FIRED" ]; then
  NOW=$(date +%s)
  MTIME=$(stat -f %m "$LAST_FIRED" 2>/dev/null || stat -c %Y "$LAST_FIRED" 2>/dev/null || echo "$NOW")
  AGE=$((NOW - MTIME))
  [ "$AGE" -lt 60 ] && exit 0
fi

# Guard 3: at least 2 meaningful file edits accumulated.
[ -f "$LOG_FILE" ] || exit 0
EDIT_COUNT=$(grep -cE $'\t(Edit|Write|MultiEdit)\t' "$LOG_FILE" 2>/dev/null || echo 0)
[ "$EDIT_COUNT" -lt 2 ] && exit 0

# Guard 4: session age — first log entry must be at least 60s old.
FIRST_TS=$(head -n 1 "$LOG_FILE" 2>/dev/null | cut -f1)
if [ -n "$FIRST_TS" ]; then
  FIRST_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$FIRST_TS" +%s 2>/dev/null || date -u -d "$FIRST_TS" +%s 2>/dev/null || echo 0)
  if [ "$FIRST_EPOCH" -gt 0 ]; then
    NOW=$(date +%s)
    SESSION_AGE=$((NOW - FIRST_EPOCH))
    [ "$SESSION_AGE" -lt 60 ] && exit 0
  fi
fi

# Mark this gate-fire so we don't re-trigger immediately.
touch "$LAST_FIRED" 2>/dev/null

# Detect auth status (cheap, bounded).
# Hooks run with a minimal PATH, so also check common install locations.
DAILYBOT_BIN=""
if command -v dailybot >/dev/null 2>&1; then
  DAILYBOT_BIN="dailybot"
else
  for p in \
    "$HOME/.local/bin/dailybot" \
    "$HOME/bin/dailybot" \
    "/usr/local/bin/dailybot" \
    /Library/Frameworks/Python.framework/Versions/*/bin/dailybot \
    "$HOME/Library/Python/*/bin/dailybot"; do
    if [ -x "$p" ] 2>/dev/null; then
      DAILYBOT_BIN="$p"
      break
    fi
  done
fi

AUTH_OK="false"
if [ -n "$DAILYBOT_BIN" ]; then
  if command -v timeout >/dev/null 2>&1; then
    RUN_AUTH="timeout 3 $DAILYBOT_BIN"
  else
    RUN_AUTH="$DAILYBOT_BIN"
  fi
  if $RUN_AUTH status --auth >/dev/null 2>&1; then
    AUTH_OK="true"
  fi
fi

# Qualitative LLM gate runs by default after deterministic gates pass.
# Set DAILYBOT_DETERMINISTIC_ONLY=1 to skip it.
# If the LLM call fails for any reason (missing key, network, malformed),
# fall back to the deterministic decision — the cheap gates already passed.
if [ "${DAILYBOT_DETERMINISTIC_ONLY:-0}" != "1" ]; then
  LLM_SCRIPT="$(dirname "$0")/gate-llm.sh"
  if [ -f "$LLM_SCRIPT" ]; then
    LLM_DECISION="$(bash "$LLM_SCRIPT" "$LOG_FILE" 2>/dev/null || true)"
    LLM_RC=$?
    # Only treat an explicit "skip" verdict as a skip. Any failure (rc!=0,
    # empty output) lets the deterministic decision stand.
    if [ "$LLM_RC" -eq 0 ] && [ -n "$LLM_DECISION" ] && [ "$LLM_DECISION" != "report" ]; then
      exit 0
    fi
  fi
fi

# Build the JSON payload. Stop hooks use top-level decision/reason fields.
if [ "$AUTH_OK" = "true" ]; then
  REASON="Significant work was completed this session. If appropriate, use the /dailybot:report skill to send a progress update before stopping."
else
  REASON="Significant work was completed this session that may be worth reporting to Dailybot, but the CLI is not installed or the user is not authenticated. If the user wants to report it, guide them through setup using the /dailybot:report skill."
fi

OUTPUT="$(jq -c -n --arg reason "$REASON" '{
  decision: "block",
  reason: $reason,
  suppressOutput: true
}' 2>/dev/null)"

[ -z "$OUTPUT" ] && exit 0
printf '%s' "$OUTPUT" | jq -e . >/dev/null 2>&1 || exit 0

printf '%s\n' "$OUTPUT"
exit 0
